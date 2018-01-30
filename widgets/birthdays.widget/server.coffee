DAV = require "dav"

#DAV.debug.enabled = true

module.exports = (server) =>
  log = server.log
  config = server.config

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
    contact.birthday = new Date(birthday.value) if birthday?
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
    loadContacts (error, contacts) ->
      birthdays = []
      for contact in contacts
        if contact.birthday?
          now = new Date()
          date = new Date(contact.birthday)
          year = date.getFullYear()
          year = null if year < 1900
          date.setFullYear(now.getFullYear())
          date.setFullYear(now.getFullYear() + 1) if date - now < 0
          days = Math.ceil((date - now) / (1000 * 60 * 60 * 24))
          age = null
          if year?
            age = now.getFullYear() - year
          birthday =
            name: contact.name
            days: days
          birthday.age = age if age?
          birthdays.push(birthday)
        else
          log.info("Contact '#{contact.name}' has no birthday")
      birthdays.sort (a,b) ->
        return -1 if a.days < b.days
        return 1 if a.days > b.days
        return 0
      log.info "Refresh complete. #{birthdays.length} birthdays found"

  refresh()

  server.handle 'birthdays', (query, respond, fail) ->
    respond(birthdays)