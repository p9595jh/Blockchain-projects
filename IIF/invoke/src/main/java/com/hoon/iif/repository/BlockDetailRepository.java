package com.hoon.iif.repository;

import com.mark.ftc.entity.BlockDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BlockDetailRepository extends JpaRepository<BlockDetail, String> {

    List<BlockDetail> findAllByTxId(String txId);
}
