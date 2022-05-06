// Copyright SIX DAY LLC. All rights reserved.

import XCTest
@testable import AlphaWallet
import TrustKeystore

class FakeUniversalLinkCoordinator: UniversalLinkCoordinatorType {
    func handleUniversalLinkOpen(url: URL) -> Bool { return false }
    func handlePendingUniversalLink(in coordinator: UrlSchemeResolver) {}
    func handleUniversalLinkInPasteboard() {}

    static func make() -> FakeUniversalLinkCoordinator {
        return .init()
    }
}

final class FakeNotificationService: NotificationService {
    init() {
        super.init(sources: [], walletBalanceService: FakeMultiWalletBalanceService())
    }
}

class InCoordinatorTests: XCTestCase {

    func testShowTabBar() {
        let config: Config = .make()
        let wallet: Wallet = .make()
        let navigationController = FakeNavigationController()
        let fas = FakeAnalyticsService()
        let keystore = FakeKeystore(wallets: [wallet])
        let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets),
        walletBalanceService: FakeMultiWalletBalanceService())
        let coordinator = ActiveWalletCoordinator(
            navigationController: navigationController,
            walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
            wallet: .make(),
            keystore: keystore,
            assetDefinitionStore: AssetDefinitionStore(),
            config: config,
            analyticsCoordinator: FakeAnalyticsService(),
            restartQueue: .init(),
            universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
            accountsCoordinator: ac,
            walletBalanceService: FakeMultiWalletBalanceService(),
            coinTickersFetcher: FakeCoinTickersFetcher(),
            tokenActionsService: FakeSwapTokenService(),
            walletConnectCoordinator: .fake(),
            notificationService: FakeNotificationService()
        )

        coordinator.start(animated: false)

        XCTAssert(coordinator.navigationController.viewControllers[0] is AccountsViewController)
        let tabbarController = coordinator.navigationController.viewControllers[1] as? UITabBarController

        XCTAssertNotNil(tabbarController)

        XCTAssert(tabbarController?.viewControllers!.count == 4)
        XCTAssert((tabbarController?.viewControllers?[0] as? UINavigationController)?.viewControllers[0] is TokensViewController)
        XCTAssert((tabbarController?.viewControllers?[1] as? UINavigationController)?.viewControllers[0] is ActivitiesViewController)
        XCTAssert((tabbarController?.viewControllers?[2] as? UINavigationController)?.viewControllers[0] is DappsHomeViewController)
        XCTAssert((tabbarController?.viewControllers?[3] as? UINavigationController)?.viewControllers[0] is SettingsViewController)
    }

    func testChangeRecentlyUsedAccount() {
        let account1: Wallet = .make(type: .watch(AlphaWallet.Address(string: "0x1000000000000000000000000000000000000000")!))
        let account2: Wallet = .make(type: .watch(AlphaWallet.Address(string: "0x2000000000000000000000000000000000000000")!))

        let keystore = FakeKeystore(
            wallets: [
                account1,
                account2
            ]
        )

        let navigationController = FakeNavigationController()
        let fas = FakeAnalyticsService()
        let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets),
        walletBalanceService: FakeMultiWalletBalanceService())
        let c1 = ActiveWalletCoordinator(
            navigationController: FakeNavigationController(),
            walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
            wallet: account1,
            keystore: keystore,
            assetDefinitionStore: AssetDefinitionStore(),
            config: .make(),
            analyticsCoordinator: FakeAnalyticsService(),
            restartQueue: .init(),
            universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
            accountsCoordinator: ac,
            walletBalanceService: FakeMultiWalletBalanceService(),
            coinTickersFetcher: FakeCoinTickersFetcher(),
            tokenActionsService: FakeSwapTokenService(),
            walletConnectCoordinator: .fake(),
            notificationService: FakeNotificationService()
        )

        c1.start(animated: false)

        XCTAssertEqual(c1.keystore.currentWallet, account1)

        let c2 = ActiveWalletCoordinator(
            navigationController: FakeNavigationController(),
            walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
            wallet: account2,
            keystore: keystore,
            assetDefinitionStore: AssetDefinitionStore(),
            config: .make(),
            analyticsCoordinator: FakeAnalyticsService(),
            restartQueue: .init(),
            universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
            accountsCoordinator: ac,
            walletBalanceService: FakeMultiWalletBalanceService(),
            coinTickersFetcher: FakeCoinTickersFetcher(),
            tokenActionsService: FakeSwapTokenService(),
            walletConnectCoordinator: .fake(),
            notificationService: FakeNotificationService()
        )

        c1.start(animated: false)

        XCTAssertEqual(c2.keystore.currentWallet, account2)
    }

    func testShowSendFlow() {
        let wallet: Wallet = .make()
        let navigationController = FakeNavigationController()
        let fas = FakeAnalyticsService()
        let keystore = FakeKeystore()
        let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets),
        walletBalanceService: FakeMultiWalletBalanceService())
        let coordinator = ActiveWalletCoordinator(
                navigationController: FakeNavigationController(),
                walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
                wallet: wallet,
                keystore: FakeKeystore(wallets: [wallet]),
                assetDefinitionStore: AssetDefinitionStore(),
                config: .make(),
                analyticsCoordinator: FakeAnalyticsService(),
                restartQueue: .init(),
                universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
                accountsCoordinator: ac,
                walletBalanceService: FakeMultiWalletBalanceService(),
                coinTickersFetcher: FakeCoinTickersFetcher(),
                tokenActionsService: FakeSwapTokenService(),
                walletConnectCoordinator: .fake(),
                notificationService: FakeNotificationService()
        )
        coordinator.start(animated: false)
        coordinator.showPaymentFlow(for: .send(type: .transaction(TransactionType.nativeCryptocurrency(TokenObject(), destination: .none, amount: nil))), server: .main, navigationController: coordinator.navigationController)

        XCTAssertTrue(coordinator.coordinators.last is PaymentCoordinator)
        XCTAssertTrue(coordinator.navigationController.viewControllers.last is SendViewController)
    }

    func testShowRequstFlow() {
        let wallet: Wallet = .make()
        let navigationController = FakeNavigationController()
        let fas = FakeAnalyticsService()
        let keystore = FakeKeystore()
        let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets),
        walletBalanceService: FakeMultiWalletBalanceService())
        let coordinator = ActiveWalletCoordinator(
            navigationController: navigationController,
            walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
            wallet: wallet,
            keystore: FakeKeystore(wallets: [wallet]),
            assetDefinitionStore: AssetDefinitionStore(),
            config: .make(),
            analyticsCoordinator: FakeAnalyticsService(),
            restartQueue: .init(),
            universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
            accountsCoordinator: ac,
            walletBalanceService: FakeMultiWalletBalanceService(),
            coinTickersFetcher: FakeCoinTickersFetcher(),
            tokenActionsService: FakeSwapTokenService(),
            walletConnectCoordinator: .fake(),
            notificationService: FakeNotificationService()
        )
        coordinator.start(animated: false)
        coordinator.showPaymentFlow(for: .request, server: .main, navigationController: coordinator.navigationController)

        XCTAssertTrue(coordinator.coordinators.last is PaymentCoordinator)
        XCTAssertTrue(coordinator.navigationController.viewControllers.last is RequestViewController)
    }

    func testShowTabDefault() {
        let navigationController = FakeNavigationController()
        let fas = FakeAnalyticsService()
        let keystore = FakeKeystore()
        let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets),
        walletBalanceService: FakeMultiWalletBalanceService())

        let coordinator = ActiveWalletCoordinator(
            navigationController: navigationController,
            walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
            wallet: .make(),
            keystore: FakeKeystore(),
            assetDefinitionStore: AssetDefinitionStore(),
            config: .make(),
            analyticsCoordinator: FakeAnalyticsService(),
            restartQueue: .init(),
            universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
            accountsCoordinator: ac,
            walletBalanceService: FakeMultiWalletBalanceService(),
            coinTickersFetcher: FakeCoinTickersFetcher(),
            tokenActionsService: FakeSwapTokenService(),
            walletConnectCoordinator: .fake(),
            notificationService: FakeNotificationService()
        )
        coordinator.start(animated: false)

        let viewController = (coordinator.tabBarController.selectedViewController as? UINavigationController)?.viewControllers[0]

        XCTAssert(viewController is TokensViewController)
    }

	//Commented out because the tokens tab has been moved to be under the More tab and will be moved
//    func testShowTabTokens() {
//        let coordinator = ActiveWalletCoordinator(
//            navigationController: FakeNavigationController(),
//            wallet: .make(),
//            keystore: FakeEtherKeystore(),
//            config: .make()
//        )
//        coordinator.showTabBar(for: .make())

//        coordinator.showTab(.tokens)

//        let viewController = (coordinator.tabBarController?.selectedViewController as? UINavigationController)?.viewControllers[0]

//        XCTAssert(viewController is TokensViewController)
//    }

    func testShowTabAlphwaWalletWallet() {
        let keystore = FakeEtherKeystore()
        switch keystore.createAccount() {
        case .success(let account):
            let wallet = Wallet(type: .real(account))
            keystore.recentlyUsedWallet = wallet
            let navigationController = FakeNavigationController()
            let fas = FakeAnalyticsService()
            let ac = AccountsCoordinator(config: .make(), navigationController: navigationController, keystore: keystore, analyticsCoordinator: fas, viewModel: .init(configuration: .changeWallets), walletBalanceService: FakeMultiWalletBalanceService())
            let coordinator = ActiveWalletCoordinator(
                    navigationController: navigationController,
                    walletAddressesStore: EtherKeystore.migratedWalletAddressesStore(userDefaults: .test),
                    wallet: wallet,
                    keystore: keystore,
                    assetDefinitionStore: AssetDefinitionStore(),
                    config: .make(),
                    analyticsCoordinator: FakeAnalyticsService(),
                    restartQueue: .init(),
                    universalLinkCoordinator: FakeUniversalLinkCoordinator.make(),
                    accountsCoordinator: ac,
                    walletBalanceService: FakeMultiWalletBalanceService(),
                    coinTickersFetcher: FakeCoinTickersFetcher(),
                    tokenActionsService: FakeSwapTokenService(),
                    walletConnectCoordinator: .fake(),
                    notificationService: FakeNotificationService()
            )
            coordinator.start(animated: false) 

            coordinator.showTab(.tokens)

            let viewController = (coordinator.tabBarController.selectedViewController as? UINavigationController)?.viewControllers[0]

            XCTAssert(viewController is TokensViewController)
        case .failure:
            XCTFail()
        }
    }
}

import PromiseKit
import Combine

final class FakeCoinTickersFetcher: CoinTickersFetcherType {

    func fetchPrices(forTokens tokens: [TokenMappedToTicker]) {
        
    }

    var tickersUpdatedPublisher: AnyPublisher<Void, Never> {
        Just(())
            .eraseToAnyPublisher()
    }

    func fetchChartHistories(addressToRPCServerKey: AddressAndRPCServer) -> Promise<[ChartHistory]> {
        return .value([])
    }

    func fetchChartHistories(addressToRPCServerKey: AddressAndRPCServer, force: Bool, periods: [ChartHistoryPeriod]) -> Promise<[ChartHistory]> {
        return Promise { _ in }
    }

    func ticker(for addressAndPRCServer: AddressAndRPCServer) -> CoinTicker? {
        return nil
    }

}
