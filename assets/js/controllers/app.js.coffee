@AppCtrl = ($scope, Wallet, $state, $rootScope,$cookieStore, $timeout, $modal) ->
  $scope.status    = Wallet.status
  $scope.settings = Wallet.settings
  $rootScope.isMock = Wallet.isMock
  
  #################################
  #           Private             #
  #################################
    
  $scope.$on('$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
    if toState.name != "login" && toState.name != "open"
      $scope.checkLogin()
  )
  
  $scope.checkLogin = () ->    
    if $scope.status.isLoggedIn == false
      if $scope.savePassword && !!$cookieStore.get("password")  
        Wallet.login($cookieStore.get("uid"), $cookieStore.get("password"))
      else 
        $state.go("login")
        
  $scope.$watch "status.isLoggedIn", (newValue) ->
    if newValue
      if Wallet.goal? && Wallet.goal.send?
        $modal.open(
          templateUrl: "partials/send"
          controller: SendCtrl
          resolve:
            paymentRequest: -> 
              Wallet.goal.send
        )
          
        Wallet.goal = null