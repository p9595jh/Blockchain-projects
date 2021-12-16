package com.hoon.iif.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class BatchDto {

    private List<String> succeeded;
    private List<String> failed;

    public String getAllTransactions() {
        List<String> transactions = Stream.of(succeeded, failed).filter(Objects::nonNull).flatMap(Collection::stream).map(tx -> tx.split("]")).filter(parts -> parts.length == 2).map(parts -> parts[1]).collect(Collectors.toList());
        if ( transactions.isEmpty() ) return "";
        return String.join(",", transactions);
    }
}
