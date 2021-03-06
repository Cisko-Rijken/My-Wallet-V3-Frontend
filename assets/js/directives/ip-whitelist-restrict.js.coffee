angular.module('walletApp').directive('ipWhitelistRestrict', ($translate, Wallet) ->
  {
    restrict: "E"
    replace: 'true'
    scope: {
    }
    templateUrl: 'templates/ip-whitelist-restrict.jade'
    link: (scope, elem, attrs) ->
      scope.settings = Wallet.settings

      scope.enableIpWhitelistRestrict = () ->
        Wallet.enableRestrictToWhiteListedIPs()

      scope.disableIpWhitelistRestrict = () ->
        Wallet.disableRestrictToWhiteListedIPs()

  }
)