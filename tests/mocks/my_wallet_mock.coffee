walletServices = angular.module("myWalletServices", [])
walletServices.factory "MyWallet", ($window, $timeout, $log, localStorageService, $cookieStore) ->
  # Erase local storage:
  localStorageService.remove("mockWallets")

  # $cookieStore.remove("uid")
  # $cookieStore.remove("password")

  # console.log localStorageService.get("mockWallets")
  
  # Wallets are stored in a cookie. If there isn't one, we'll create it.
  unless localStorageService.get("mockWallets") 
    localStorageService.set("mockWallets", {
      "test": {
        password: "test"
        two_factor: null
        email_verified: true
        accounts: [
          {label: "Savings", archived: false, balance: 300000000 - 25000000, receive_addresses: []},
          {label: "Mobile", archived: false, balance: 25000000 - 1500000, receive_addresses: ["13QsKpDMchnssikZEaJKdkTX7pycFEcTi1"]}
        ]
        transactions: [
          {hash: "aaaa", amount: 300000000, confirmations: 13, doubleSpend: false, coinbase: false, intraWallet: false, from_account: null, from_addresses: ["1D2YzLr5qvrwMSm8onYbns5BLJ9jwzPHcQ"], to_account: 0, to_addresses: [], txTime: 1331300839},
          {hash: "aaab", amount: -25000000, confirmations: 3, doubleSpend: false, coinbase: false, intraWallet: true, from_account: 0, from_addresses: [], to_account: 1, to_addresses: [], note: null, txTime:   2000000000},
          {hash: "afsdfsdkj", amount: -1500000, confirmations: 1, doubleSpend: false, coinbase: false, intraWallet: false, from_account: 1, from_addresses: [], to_account: null, to_addresses: ["1LJuG6yvRh8zL9DQ2PTYjdNydipbSUQeq"] ,note: null, txTime:   8200000000},
          {hash: "afsdfsdkj", amount: -1500000, confirmations: 1, doubleSpend: false, coinbase: false, intraWallet: false, from_account: null, from_addresses: ["somewhere"], to_account: null, to_addresses: ["some_legacy_archived_address_with_money"] ,note: null, txTime:   8300000000},
        ]
        legacyAddresses: {
          "some_legacy_address":            {privateKey: "legacy_private_key", label: "Old"}
          "some_legacy_watch_only_address": {privateKey: null, label: "Paper wallet"}
          "some_legacy_address_without_label": {privateKey: "legacy_no_label_private_key", label: null}
          "some_legacy_archived_address":   {privateKey: "legacy_archived", archived: true}
          "some_legacy_archived_address_with_money":   {privateKey: "legacy_archived_with_money", archived: true}
          
        }
        
        notes: {
          "aaaa" : "Salary"
        }
      },
      "test-unverified" : {
        password: "test"
        two_factor: null
        email_verified: false
        accounts: [
          {label: "Spending", balance: 0, receive_addresses: []}
        ]
        transactions: []
        notes: {}
        legacyAddresses: {}
      },
      "test-2FA" : {
        password: "test"
        email_verified: true
        two_factor: 4
        two_factor_code: "123456"
        accounts: [
          {label: "Spending", balance: 0, receive_addresses: []}
        ]
        transactions: []
        notes: {}
        legacyAddresses: {}
      }
    })
        
  uid = undefined
  
  isSynchronizedWithServer = true # In the sense that the server is up to date
  
  myWallet = {}
  accounts = []
    
  transactions = []
  notes = {}
  legacyAddresses = []
  
  language = "en"
  email = "steve@me.com"
  mobile = "+31 12345678"
  
  feePolicy = 0

  monitorFunc = undefined  # New system
  eventListener = undefined # Old system
  
  mockRules = {shouldFailToSend: false, shouldFailToCreateWallet: false}
  
  myWallet.addressBook = { # The same for everyone
    "17gJCBiPBwY5x43DZMH3UJ7btHZs6oPAGq": "John"
    "1LJuG6yvRh8zL9DQ2PTYjdNydipbSUQeq": "Alice"
  }

  paymentRequests = []
  
  mockPaymentRequestAddressStack = [ # Same for everyone
    "1Hj9XKGY6Fh8koVh6CuTJsQnuiSQrd9iCx"
    "1Bp85Lymp2ViRZwhbsD8NnDgRkEyai9w7i"
    "1LeoeftCD56juxPuGYh1m1bSrPxkBu44aH"
    "1B4mSrAoDCufBDNaRbBLVEMiKyuGbG2hYh"
    "17Nxxw6nS8bqUSGEZ6a3YWsCjCr15reLiy"
    "1b1da7mU4KAue6BBXYFD7wDfNRmRi3bjH"
    "1KERjvoD6yPY4qEovfaTmgwcR6SfhMoeSJ"
    "1JGAyzFGQNpQhjbD1ue528QhuYtbRos7Ax"
    "1C9KKvTW94C4wiwqL5whVPUEAwmGJLXEvt"
    "12L5nz6AYye5DJiWbgCAvkSJBUok1WZPij"
    "1J85hDKybYPXcXY78izocQpezEShW6xfc8"
    "1ggDhwUX5LRsJHeeEYn8MEimBKNco2Ywq"
    "1Gyz5MPYY1ZKLcvmXSPHMAi1xpHbdCGaUN"
    "1M4YSYCarkSeNUk9D1o3F7hHFL9c2EYums"
    "1LKwobBwhVwq4HF7NqBeebVg4UTLgS3bc5"
    "1MgYrhUtb5RfV5DTaWiLGTbSMVKuFNVC7Y"
    "1Q57Pa6UQiDBeA3o5sQR1orCqfZzGA7Ddp"
  ]
  
  myWallet.getLegacyAddressBalance = (address) ->
    return 0.1
  
  myWallet.getHDWallet = () ->
    myWallet 
    
  myWallet.getPassphraseString = () ->
    return "banana big me hungry"
    
  myWallet.fetchWalletJson = (uid, dummy1, dummy2, password, two_factor_code, success, needs_2fa, wrong_2fa) ->
    if wallet = localStorageService.get("mockWallets")[uid]
      myWallet.uid = uid
      eventListener("did_set_guid")
      
      if wallet.two_factor
        if two_factor_code
          if two_factor_code != wallet.two_factor_code
            wrong_2fa()
        else
          needs_2fa(wallet.two_factor)
          return
      
      unless password && password == wallet.password
        monitorFunc({type: "error", message: "Wrong password", code: 0});
        return
      
      myWallet.password = password
    
      this.refresh()
    
      success()
      eventListener("on_wallet_decrypt_finish")
      eventListener("did_multiaddr")
      return
      
    else
      $log.error "Wallet not found"
      eventListener("wallet not found")
      
  myWallet.createNewWallet = (email, pwd, language, currency, success, fail) ->
    uid = String(Math.floor((Math.random() * 100000000) + 1))
    
    if mockRules.shouldFailToCreateWallet
      fail({message: "Mock asked to fail"})
      return
    
    wallets = localStorageService.get("mockWallets")
    if wallets[uid]
      fail({message: "Wallet already exists"})
    else
      wallets[uid] = {
        password: pwd
        accounts: [
          {label: "Spending", archived: false, balance: 0, receive_addresses: []}
        ]
        transactions: []
        language: language
        currency: currency
      }
      localStorageService.set("mockWallets", wallets)
      success(uid)
  
  myWallet.logout = () ->
    eventListener("logging_out")
    myWallet.uid = undefined
    myWallet.password = undefined
    transactions = []
    paymentRequests = []
    accounts = []
    if !(karma?) || !karma
      window.location = ""
      
  myWallet.isCorrectMainPassword = (candidate) ->
    return candidate == myWallet.password
    
  myWallet.changePassword = (newPassword) ->
    myWallet.password = newPassword
    # wallets = localStorageService.get("mockWallets")
    # wallets[myWallet.uid].password = newPassword
    # localStorageService.set("mockWallets", wallets)
      
  myWallet.get_ticker = (success, fail) ->
    success({
      USD: {"15m": 250, symbol: "€"}
      EUR: {"15m": 300, symbol: "$"}
    })
 
  myWallet.getLanguage = () ->
    return language
    
    
  myWallet.get_account_info = (callback) ->
    callback({
      email: email
      email_verified: 1
      sms_number: mobile
      sms_verified: 0
      password_hint1: "Same as username"
      language: language
      currency: "USD"
      block_tor_ips: 0
    })
    
  myWallet.getLanguages = () ->
    {de: "Deutch", en: "English", nl: "Nederlands"}
    
  myWallet.getCurrencies = () ->
    {USD: "US Dollar", EUR: "Euro"}

  myWallet.change_email = (newVal, success, error) ->
    email = newVal
    success()
    
  myWallet.changeMobileNumber = (newVal, success, error) ->
    mobile = newVal
    success()
    
  myWallet.verifyMobile = (code, success, error) ->
    success()
    
  myWallet.update_password_hint1 = (value, success, fail) ->
    success()
    
  myWallet.change_language = (newLanguage) ->
    language = newLanguage
    
  myWallet.change_local_currency = (newCurrency) ->
    currency = newCurrency
    
  myWallet.getAccounts = () ->  
    theAccounts = []
    for i in [0..myWallet.getAccountsCount()]
      theAccounts.push myWallet.getAccount(i)
    return theAccounts
    
  myWallet.getAccountsCount = () ->
    return accounts.length
    
  myWallet.getLabelForAccount = (idx) ->
    return accounts[idx].label
    
  myWallet.getBalanceForAccount = (idx) ->
    return accounts[idx].balance
    
  myWallet.createAccount = (label) ->
    accounts.push {label: label, archived: false, balance: 0, receive_addresses: [] }
    myWallet.sync()
    
  myWallet.setLabelForAccount = (idx, label) ->
    accounts[idx].label = label
    
  myWallet.getAllTransactions = (idx) ->
    res = []
    for transaction in transactions
      res.push transaction
    
    return res
    
  myWallet.getNote = (hash) ->
    notes[hash]
    
  myWallet.setNote = (hash, text) ->
    notes[hash] = text
    myWallet.sync()
    return
    
  # Amount in Satoshi
  myWallet.sendBitcoinsForAccount = (fromAccountIndex,toAddress, amount, fee, note, success, error) ->
    if mockRules.shouldFailToSend
      error({message: "Reason for failure"})
      return
      
    # A few sanity checks (not complete)
    if amount > accounts[fromAccountIndex].balance
      error({message: "Insufficient funds"})
      return
    
    ###
    The MyWallet mock parses transactions by just copying them, so the following 
    transaction is what a real transaction would look like  *after* processing. 
    
    The real transaction may have several inputs (from receiving and change address 
    for this account). A new change address may need to be generated.
    
    Transaction parsing should be able to figure out which account was the sender and 
    change address and which address represents a recipient.
    ###
    transaction  = {hash: "hash-" + (new Date()).getTime(), amount: -amount, confirmations: 0, doubleSpend: false, coinbase: false, intraWallet: false, from_account: fromAccountIndex, from_addresses: [], to_account: null, to_addresses: [toAddress], note: null, txTime: (new Date()).getTime()}

    # MyWallet stores transaction locally (so it already knows it by the time
    # it receives the websocket notification).

    transactions.push transaction
    accounts[fromAccountIndex].balance -= amount
    
    # Blockchain.info will know about these transactions:
    cookie = localStorageService.get("mockWallets")
    cookie[this.uid].accounts[fromAccountIndex].balance -= amount
    cookie[this.uid].transactions.push transaction
    localStorageService.set("mockWallets", cookie)
    
    success()
    
    return
    
  myWallet.sendToEmail = (accountIdx, value, fixedFee, email, successCallback, errorCallback) ->
    successCallback()  
    
  # Amount in Satoshi  
  myWallet.getAccount = (index) ->
    if index < 0
      return
      
    account = {}
        
    account.getPaymentRequests = () ->
      requests = []
      for request in paymentRequests
        requests.push request if request.account == index
        
      return requests 
    
    account.generatePaymentRequest = (amount) ->
      # It should generate a new receive address or reuse a cancelled address
      # (never reuse an addres that actually received btc). It should increase
      # the tally in the wallet.
          
      if mockPaymentRequestAddressStack.length == 0
        $log.error "No more mock payment request addresses; please refresh."
        return {amount: 0, address: "No more mock addresses available"}
      
      address = mockPaymentRequestAddressStack.pop()
    
      request = {address: address, amount: amount, account: index, paid: 0, complete: false, canceled: false}

      accounts[index].receive_addresses.push address
    
      paymentRequests.push request
      
      myWallet.sync()
      
      return request
      
    account.cancelPaymentRequest = (address) ->
      for candidate in paymentRequests
        if candidate.address == address
          paymentRequests.pop(candidate)
          mockPaymentRequestAddressStack.push(address)
          myWallet.sync()
          return true
        
      return false
    
    account.updatePaymentRequest = (address, amount) ->
      for candidate in paymentRequests
        if candidate.address == address
          candidate.amount = amount
          myWallet.sync()
          return candidate
        
    account.acceptPaymentRequest = (address) ->
      for candidate in paymentRequests
        if candidate.address == address
          myWallet.sync()
          candidate.complete = true
          
    account.getAddressForPaymentRequest = (request) ->
      return request.address
    
    return account
  
  myWallet.getPaymentRequestsForAccount = (idx) ->
    myWallet.getAccount(idx).getPaymentRequests()
  
  myWallet.generatePaymentRequestForAccount = (idx, amount) ->
    myWallet.getAccount(idx).generatePaymentRequest(amount)

  myWallet.cancelPaymentRequestForAccount = (idx, address) ->
    myWallet.getAccount(idx).cancelPaymentRequest(address)
    
  myWallet.updatePaymentRequestForAccount = (idx, address, amount) ->
    myWallet.getAccount(idx).updatePaymentRequest(address, amount)
    
  myWallet.acceptPaymentRequestForAccount = (idx, address) ->
    myWallet.getAccount(idx).acceptPaymentRequest(address)
    
  myWallet.addEventListener = (func) ->
    eventListener = func
    
  myWallet.monitor = (func) ->
    monitorFunc = func
    
  # Pending refactoring of MyWallet:
  $window.symbol_local = {code: "USD",conversion: 250000.001, local: true, name: "Dollar", symbol: "$", symbolAppearsAfter: false}
    
  myWallet.isSynchronizedWithServer = () ->
    return isSynchronizedWithServer
    
  myWallet.recommendedTransactionFeeForAccount = () ->
    return 10000
    
    
  ####################
  # Legacy addresses #
  ####################
  myWallet.getAllLegacyAddresses = () ->
    res = []
    for key, value of legacyAddresses
      res.push key
    return res
    
  myWallet.getLegacyActiveAddresses = () ->
    activeAddresses = []
    for key, value of legacyAddresses
      unless value.archived
        activeAddresses.push key
    return activeAddresses
    
  myWallet.getLegacyAddressLabel = (address) ->
    return legacyAddresses[address].label
    
  myWallet.isWatchOnlyLegacyAddress = (address) ->
    return legacyAddresses[address].privateKey == null
    
  myWallet.archiveLegacyAddr = (address) ->
    return
  
  myWallet.unArchiveLegacyAddr = (address) ->
    return
    
  myWallet.deleteLegacyAddress = (address) ->
    return
    
  myWallet.makePairingCode = () ->
    return ""
    
  ############################################################
  # Simulate spontanuous behavior when using mock in browser #
  ############################################################

    
  ###################################
  # Fake methods useful for testing #
  ###################################
  
  myWallet.sync = () ->
    isSynchronizedWithServer = false
    
    if myWallet.pendingSync != undefined
      $timeout.cancel(myWallet.pendingSync)
      
    myWallet.pendingSync = $timeout((->
      # Save payment requests and accounts in our cookie:
      cookie = localStorageService.get("mockWallets")
      unless cookie[myWallet.uid]
        console.log "User " + myWallet.uid + " not found in local storage."
        console.log localStorageService.get("mockWallets")
        return 
        
      cookie[myWallet.uid].paymentRequests = paymentRequests
      cookie[myWallet.uid].accounts = accounts
      cookie[myWallet.uid].notes = notes
      cookie[myWallet.uid].legacyAddresses = legacyAddresses
      
            
      localStorageService.set("mockWallets", cookie)
      isSynchronizedWithServer = true
    ), 5000)
    
  
  myWallet.refresh = () ->
    accounts = angular.copy(localStorageService.get("mockWallets")[this.uid].accounts)
    transactions = angular.copy(localStorageService.get("mockWallets")[this.uid].transactions)
    notes = angular.copy(localStorageService.get("mockWallets")[this.uid].notes)
    legacyAddresses = angular.copy(localStorageService.get("mockWallets")[this.uid].legacyAddresses)
    
    
    if localStorageService.get("mockWallets")[this.uid].paymentRequests
      paymentRequests = angular.copy(localStorageService.get("mockWallets")[this.uid].paymentRequests)      
      # Update the stack of remaning payment addresses:
      for request in paymentRequests 
        index = mockPaymentRequestAddressStack.indexOf(request.address)
        if index > -1
          mockPaymentRequestAddressStack.splice(index,1)
  
  myWallet.isValidAddress = (address) ->
    withoutWhiteSpace = address.trim()
    # Reject if there are spaces inside the address:
    return withoutWhiteSpace.indexOf(" ") == -1 && withoutWhiteSpace.indexOf("@") == -1
    
  myWallet.unsetTwoFactor = (success, error) ->
    success()
    
  myWallet.setTwoFactorSMS = (success, error) ->
    success()
    
  myWallet.setTwoFactorEmail = (success, error) ->
    success()
    
  myWallet.setTwoFactorGoogleAuthenticator = (success, error) ->
    success("google_secret")
    
  myWallet.confirmTwoFactorGoogleAuthenticator = (code, success, error) ->
    if code == "123456"
      success()
    else
      error()
    
  myWallet.getFeePolicy = () ->
    return feePolicy
    
  myWallet.setFeePolicy = (policy) ->
    feePolicy = policy
    return
    
  myWallet.update_tor_ip_block = (enabled, successCallback, errorCallback) ->
    successCallback()
    
  #####################################
  # Tell the mock to behave different # 
  #####################################
  myWallet.mockShouldFailToSend = () ->
    mockRules.shouldFailToSend = true
    
  myWallet.mockShouldFailToCreateWallet = () ->
    mockRules.shouldFailToCreateWallet = true
    
  myWallet.mockShouldReceiveNewTransaction = (address="13QsKpDMchnssikZEaJKdkTX7pycFEcTi1", from="17gJCBiPBwY5x43DZMH3UJ7btHZs6oPAGq", amount=400000, note="Thanks for the tea") ->
    this.mockProcessNewTransaction {hash: "mock-receive-" + (new Date()).getTime(), amount: amount, confirmations: 0, doubleSpend: false, coinbase: false, intraWallet: false, from_account: null, from_addresses: [from], to: address , note: note, txTime: (new Date()).getTime()}
    
    eventListener("on_tx")
    
  myWallet.mockProcessNewTransaction = (transaction) ->      
    # Does the "to" address match any payment requests? If so, update them with the amount:
    for request in paymentRequests
      if request.address == transaction.to
        request.paid += parseInt(transaction.amount) # The real thing should use the amount per output
        if request.paid == request.amount
          request.complete = true
          eventListener("hw_wallet_accepted_payment_request", {amount: request.amount})
          myWallet.sync()
        else if request.paid > 0 && request.amount > request.paid
          eventListener("hw_wallet_payment_request_received_too_little", {amountRequested: request.amount, amountReceived: request.paid})
        else if request.amount < request.paid
          eventListener("hw_wallet_payment_request_received_too_much", {amountRequested: request.amount, amountReceived: request.paid})

        break
    
    
    # Match "to" address to receive address to figure out which account it was sent to:
    for account in accounts
      for address in account.receive_addresses
        if address == transaction.to
          index = accounts.indexOf(account)
          transaction.to_account = index
          transaction.to_addresses = []
          transaction.to = undefined
          accounts[index].balance += transaction.amount
          
          transactions.push transaction
          
          # Update the "blockchain" in our cookie:
          cookie = localStorageService.get("mockWallets")
          cookie[this.uid].accounts[index].balance += transaction.amount
          cookie[this.uid].transactions.push transaction
          localStorageService.set("mockWallets", cookie)
          
          break

  myWallet.mockShouldReceiveNewBlock = () ->
    eventListener("on_block")
  
  return myWallet 