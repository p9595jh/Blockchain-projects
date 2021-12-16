package com.hoon.iif.repository;

import com.mark.ftc.entity.Block;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BlockRepository extends JpaRepository<Block, String> {

    Optional<Block> findTopByOrderByNumberDesc();

    Optional<Block> findFirstByNumber(Long number);
}
