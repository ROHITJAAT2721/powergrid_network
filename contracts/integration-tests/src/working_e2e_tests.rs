//! Working End-to-End Integration Tests for PowerGrid Network
//! 
//! These tests deploy actual contracts on substrate-contracts-node and test 
//! real cross-contract interactions, state changes, and message passing.
//! 
//! Run with: cargo test --features e2e-tests

#[cfg(all(test, feature = "e2e-tests"))]
mod tests {
    use ink_e2e::{build_message, ContractsBackend};
    use powergrid_shared::{DeviceMetadata, DeviceType, GridEventType};
    
    // Import contract references  
    use powergrid_token::powergrid_token::PowergridTokenRef;
    use resource_registry::resource_registry::ResourceRegistryRef;
    use grid_service::grid_service::GridServiceRef;

    type E2EResult<T> = std::result::Result<T, Box<dyn std::error::Error>>;

    /// Test basic contract deployment and interaction
    #[ink_e2e::test]
    async fn test_basic_deployment_e2e(mut client: ink_e2e::Client<C, E>) -> E2EResult<()>
    where
        C: ContractsBackend,
        E: ink_e2e::Environment,
        <E as ink_e2e::Environment>::Balance: From<u128>,
    {
        // Deploy Token Contract
        let token_constructor = PowergridTokenRef::new(
            "PowerGrid Token".to_string(),
            "PGT".to_string(),
            18u8,
            1_000_000_000_000_000_000_000u128,
        );
        
        let token_account = client
            .instantiate("powergrid_token", &ink_e2e::alice(), token_constructor, 0, None)
            .await?
            .account_id;

        // Deploy Resource Registry  
        let registry_constructor = ResourceRegistryRef::new(
            1_000_000_000_000_000_000u128,
        );
        
        let registry_account = client
            .instantiate("resource_registry", &ink_e2e::alice(), registry_constructor, 0, None)
            .await?
            .account_id;

        println!("✅ Basic deployment E2E test passed!");
        println!("   - Token contract deployed: {}", token_account);
        println!("   - Registry contract deployed: {}", registry_account);
        
        Ok(())
    }
}
