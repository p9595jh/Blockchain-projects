package com.hoon.iif.service;

import com.mark.ftc.dto.BatchDto;
import com.mark.ftc.entity.Block;
import com.mark.ftc.entity.BlockDetail;
import com.mark.ftc.repository.BlockDetailRepository;
import com.mark.ftc.repository.BlockRepository;
import com.mark.ftc.util.BlockConverter;
import com.mark.ftc.util.TypeConverter;
import org.codehaus.jackson.map.ObjectMapper;
import org.hyperledger.fabric.gateway.ContractEvent;
import org.hyperledger.fabric.protos.common.Common;
import org.hyperledger.fabric.sdk.BlockEvent;
import org.hyperledger.fabric.sdk.helper.Utils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class BlockService {

    @Autowired
    private BlockRepository blockRepository;

    @Autowired
    private BlockDetailRepository blockDetailRepository;

    public long processBlockEvent(BlockEvent event) {
        long blockNumber = event.getBlockNumber();
        if ( event.getBlock() != null ) {
            Common.BlockHeader header = event.getBlock().getHeader();
            Block block = new Block();
            block.setHash(BlockConverter.currentBlockhash(header));
            block.setPrevHash(Utils.toHexString(header.getPreviousHash().toByteArray()));
            block.setNumber(blockNumber);
            blockRepository.saveAndFlush(block);
        }
        return blockNumber;
    }

    public void processContractEvent(ContractEvent event) {
        if ( event.getChaincodeId().equalsIgnoreCase("themedium") ) {
            String eventName = event.getName();
            Optional<byte[]> optionalPayload = event.getPayload();
            BlockEvent.TransactionEvent transactionEvent = event.getTransactionEvent();
            Common.BlockHeader header = transactionEvent.getBlockEvent().getBlock().getHeader();
            if ( eventName.equalsIgnoreCase("batch") && optionalPayload.isPresent() ) {
                String payload = TypeConverter.bytesToString(optionalPayload.get());
                try {
                    ObjectMapper objectMapper = new ObjectMapper();
                    BatchDto batchDto = objectMapper.readValue(payload, BatchDto.class);
                    BlockDetail blockDetail = new BlockDetail();
                    blockDetail.setHash(BlockConverter.currentBlockhash(header));
                    blockDetail.setNumber(header.getNumber());
                    blockDetail.setTxId(transactionEvent.getTransactionID());
                    blockDetail.setNonce(Utils.toHexString(transactionEvent.getNonce()));
                    blockDetail.setTransactions(batchDto.getAllTransactions());
                    blockDetailRepository.saveAndFlush(blockDetail);
                } catch (Exception ignored) {}
            }
        }
    }

    public long getLastBlockNumber() {
        Optional<Block> blockOptional = blockRepository.findTopByOrderByNumberDesc();
        if ( blockOptional.isPresent() ) return blockOptional.get().getNumber();
        return 0L;
    }
}
