package com.hoon.iif.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import javax.validation.constraints.NotNull;
import java.math.BigInteger;

@Getter
@Setter
@NoArgsConstructor
public class FeeDto {

    @NotNull
    private String address;

    @NotNull
    private BigInteger fee;
}
