module coin_sample::mycoin {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    #[test_only]
    use sui::test_scenario;

    struct MYCOIN has drop {}

    fun init(witness: MYCOIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata)
            = coin::create_currency<MYCOIN>(
            witness,
            2, // decimals
            b"BHAT", // symbol
            b"Black Witches Hat", // name
            b"my coin", // description
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx))
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<MYCOIN>, amount:u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    public entry fun burn(treasury_cap: &mut TreasuryCap<MYCOIN>, coin: Coin<MYCOIN>) {
        coin::burn(treasury_cap, coin);
    }


    #[test]
    public fun test_mint() {
        let user = @0xA;
        let receiver = @0xB;
        let num_coins = 10;

        let scenario_val = test_scenario::begin(user);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            init(MYCOIN {}, ctx)
        };

        test_scenario::next_tx(scenario, user);
        {
            let treasuryCap = test_scenario::take_from_sender<TreasuryCap<MYCOIN>>(scenario);
            mint(&mut treasuryCap, num_coins, receiver, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, treasuryCap);
        };

        test_scenario::next_tx(scenario, receiver);
        {
            let mycoin = test_scenario::take_from_sender<Coin<MYCOIN>>(scenario);
            assert!(coin::value(&mycoin) == num_coins, 3);
            test_scenario::return_to_sender(scenario, mycoin);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    public fun test_burn() {
        let user = @0xA;
        let num_coins = 10;

        let scenario_val = test_scenario::begin(user);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            init(MYCOIN {}, ctx)
        };

        test_scenario::next_tx(scenario, user);
        {
            let treasuryCap = test_scenario::take_from_sender<TreasuryCap<MYCOIN>>(scenario);
            mint(&mut treasuryCap, num_coins, user, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, treasuryCap);
        };

        test_scenario::next_tx(scenario, user);
        {
            let treasuryCap = test_scenario::take_from_sender<TreasuryCap<MYCOIN>>(scenario);
            let mycoin = test_scenario::take_from_sender<Coin<MYCOIN>>(scenario);

            let supply_before_burn = coin::total_supply(&mut treasuryCap);
            assert!(supply_before_burn == 10, 3);

            burn(&mut treasuryCap, mycoin);

            let supply_after_burn = coin::total_supply(&mut treasuryCap);
            assert!(supply_after_burn == 0, 3);

            test_scenario::return_to_sender(scenario, treasuryCap);
        };
        test_scenario::end(scenario_val);
    }
}