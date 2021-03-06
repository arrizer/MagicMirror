DAV = require "dav"

#DAV.debug.enabled = true

module.exports = (server) =>
  log = server.log
  config = server.config

  hasInitialData = no
  birthdays = []

  loadVCards = (next) ->
    log.info "Loading VCards from server..."

    transport = new DAV.transport.Basic(new DAV.Credentials(username: config.username, password: config.password))
    client = new DAV.Client(transport)
  
    client.createAccount(server: config.server, accountType: 'carddav', loadObjects: yes)
    .then (account) ->
      vcards = []
      for addressBook in account.addressBooks
        log.info "Reading #{addressBook.objects.length} contacts from address book '#{addressBook.displayName}'"
        for object in addressBook.objects
          vcards.push object.addressData
      next(null, vcards)
    .catch (error) ->
      log.error(error)
      next(error)

  parseVCard = (vcard) ->
    contact = {}
    properties = {}
    regexp = /([^:;]+);?([^:]*?)\:([^\n]+)\r\n/g
    while match = regexp.exec(vcard)
      key = match[1]
      properties[key] =
        arguments: match[2]
        value: match[3]
    name = properties['FN']
    birthday = properties['BDAY']
    throw new Error("No full name found in #{vcard}") unless name?
    contact.name = name.value
    if birthday? and match = /(\d{4})\-(\d{2})\-(\d{2})/.exec(birthday.value)
      contact.birthday = new Date(parseInt(match[1]), parseInt(match[2]) - 1, parseInt(match[3]))
    return contact

  loadContacts = (next) ->
    loadVCards (error, vcards) ->
      return next(error) if error?
      contacts = []
      for vcard in vcards
        try
          contacts.push(parseVCard(vcard))
        catch error
          log.error(error)
      next null, contacts

  refresh = ->
    log.info "Refreshing contacts..."
    loadContacts (error, contacts) ->
      birthdays = []
      for contact in contacts
        if contact.birthday?
          now = new Date()
          now.setHours(0)
          now.setMinutes(0)
          now.setSeconds(0)
          date = new Date(contact.birthday)
          year = date.getFullYear()
          year = null if year < 1900
          oneDay = (1000 * 60 * 60 * 24)
          date.setFullYear(now.getFullYear())
          date.setFullYear(now.getFullYear() + 1) if date - now < (oneDay * -1)
          days = Math.ceil((date - now) / oneDay)
          age = null
          if year?
            age = now.getFullYear() - year
          birthday =
            name: contact.name
            days: days
          birthday.age = age if age?
          birthdays.push(birthday)
        else
          log.info("Contact '#{contact.name}' has no birthday") unless hasInitialData
      birthdays.sort (a,b) ->
        return -1 if a.days < b.days
        return 1 if a.days > b.days
        return 0
      log.info "Refresh complete. #{birthdays.length} birthdays found"
      hasInitialData = yes

  refresh()

  setInterval (-> refresh()), (1000 * 60 * 5)

  server.handle 'birthdays', (query, respond, fail) ->
    upcomingBirthdays = birthdays.filter((birthday) -> birthday.days <= config.daysAhead)
    response =
      hasInitialData: hasInitialData
      birthdays: upcomingBirthdays
    respond(response)