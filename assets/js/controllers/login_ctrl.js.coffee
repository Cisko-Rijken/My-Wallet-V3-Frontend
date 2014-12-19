@LoginCtrl = ($scope, $log, Wallet, $cookieStore, $modal, $state) ->
  $scope.status = Wallet.status    
  $scope.settings = Wallet.settings
  $scope.uid = $cookieStore.get("uid")
  $scope.twoFactorCode = ""
  $scope.creatingAccount = false
  
  if !!$cookieStore.get("password")      
    $scope.password = $cookieStore.get("password")
  
  $scope.login = () ->
    Wallet.clearAlerts()
            
    if !$scope.settings.needs2FA
      Wallet.login($scope.uid, $scope.password)
    else if $scope.twoFactorCode != ""
      Wallet.login($scope.uid, $scope.password, $scope.twoFactorCode)
    
    $cookieStore.put("uid", $scope.uid)
    if $scope.savePassword
       $cookieStore.put("password", $scope.password)
    
  $scope.create = () ->
    Wallet.clearAlerts()
    
    $scope.creatingAccount = true

    modalInstance = $modal.open(
      templateUrl: "partials/signup"
      controller: SignupCtrl
      backdrop: "static"
      keyboard: false
      windowClass: "signup"
      size: "lg"
    )

  $scope.$watch "status.isLoggedIn", (newValue) ->
    if newValue
      # $state.go("dashboard")
      $state.go("transactions", {accountIndex: null})
      