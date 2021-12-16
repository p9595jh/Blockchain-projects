package com.hoon.iif.service;

import com.mark.ftc.repository.AdminOperationRespository;
import com.mark.ftc.util.FtcJson;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigInteger;

@Service
public class InvokeService {

    @Autowired
    private AdminOperationRespository adminOperationRespository;

    @Autowired
    private FtcJson jsonUtil;

    public String getBalance(String contractAddress, String address) {
        return adminOperationRespository.evaluate("GetBalanceOf", contractAddress, address);
    }

    public String getTransactionCount(String contractAddress, String address) {
        return adminOperationRespository.evaluate("GetTransactionCount", contractAddress, address);
    }

    public String getFee(String contractAddress, String address) {
        return adminOperationRespository.evaluate("GetFee", contractAddress,  address);
    }

    public String setFee(String contractAddress, String address, BigInteger fee) {
        return adminOperationRespository.submit("SetFee", contractAddress, address, fee.toString());
    }

    public String getFeeCollector(String contractAddress) {
        return adminOperationRespository.evaluate("GetFeeCollector", contractAddress);
    }

    public String setFeeCollector(String contractAddress, String feeCollector) {
        return adminOperationRespository.submit("SetFeeCollector", contractAddress, feeCollector);
    }

    public String setBalance(String contractAddress, String address, BigInteger balance) {
        return adminOperationRespository.submit("SetBalanceOf", contractAddress, address, balance.toString());
    }

    public String setContractManagerOwner(String contractAddress, String address, int nonce, String owner) {
        return adminOperationRespository.submit("SetContractManagerOwner", contractAddress, address, nonce, owner);
    }

}
