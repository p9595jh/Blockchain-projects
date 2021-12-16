package com.hoon.iif.controller;

import com.hoon.iif.dto.BalanceDto;
import com.hoon.iif.dto.FeeDto;
import com.hoon.iif.service.InvokeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

@RestController
@RequestMapping(path = "/api/ftcs")
public class InvokeController {

    @Autowired
    private InvokeService invokeService;

    private final String contractAddress = "-";

    @RequestMapping(method = RequestMethod.GET, path = "/balances/{address}")
    public ResponseEntity<?> getBalance(@PathVariable String address) {
        String res = invokeService.getBalance(contractAddress, address);
        return ResponseEntity.ok(res);
    }

    @RequestMapping(method = RequestMethod.POST, path = "/balances")
    public ResponseEntity<?> setBalance(@RequestBody @Valid BalanceDto req) {
        String res = invokeService.setBalance(contractAddress, req.getAddress(), req.getBalance());
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @RequestMapping(method = RequestMethod.GET, path = "/fees/{address}")
    public ResponseEntity<?> getFee(@PathVariable String address) {
        String res = invokeService.getFee(contractAddress, address);
        return ResponseEntity.ok(res);
    }

    @RequestMapping(method = RequestMethod.POST, path =  "/fees")
    public ResponseEntity<?> setFee(@RequestBody @Valid FeeDto req) {
        String res = invokeService.setFee(contractAddress, req.getAddress(), req.getFee());
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

}
