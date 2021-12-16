package com.hoon.iif.repository;

import com.hoon.iif.util.JsonUtil;
import lombok.Getter;
import org.hyperledger.fabric.gateway.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

import java.nio.file.Path;
import java.nio.file.Paths;

@Repository
@Getter
public class AdminOperationRespository {

    @Autowired
    private JsonUtil jsonUtil;

    @Value("${fabric.wallet.path}")
    private String walletPathString;

    @Value("${fabric.network.configPath}")
    private String ccpPath;

    @Value("${fabric.ca.appUser.id}")
    private String appUserId;

    @Value("${fabric.networkName}")
    private String networkName;

    @Value("${fabric.contractName}")
    private String contractName;

    private Gateway gateway;
    private Contract contract;
    private Network network;

    private final String defaultFuncName = "AdminOperations";

    public void init() throws Exception {
        Path walletPath = Paths.get(walletPathString);
        Wallet wallet = Wallets.newFileSystemWallet(walletPath);

        Path networkConfigPath = Paths.get(ccpPath);

        Gateway.Builder builder = Gateway.createBuilder();
        builder.identity(wallet, appUserId).networkConfig(networkConfigPath).discovery(true);

        gateway = builder.connect();
        network = gateway.getNetwork(networkName);
        contract = network.getContract(contractName);
    }

    // read
    public String evaluate(String functionName, Object... params) {
        try {
            byte[] result = contract.evaluateTransaction(defaultFuncName, functionName, jsonUtil.toFtcArgJsonString(params));
            return new String(result);

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    // write
    public String submit(String functionName, Object... params) {
        try {
            byte[] result = contract.submitTransaction(defaultFuncName, functionName, jsonUtil.toFtcArgJsonString(params));
            return new String(result);

        } catch(Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
