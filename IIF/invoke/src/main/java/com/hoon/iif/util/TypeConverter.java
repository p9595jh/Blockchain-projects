package com.hoon.iif.util;

import com.google.common.io.BaseEncoding;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;

public class TypeConverter {
    public static BigInteger hexToBigInteger(String input) {
        if ( input.startsWith("0x") ) {
            return new BigInteger(input.substring(2), 16);
        } else {
            return new BigInteger(input, 10);
        }
    }

    public static BigInteger bytesToBigInteger(byte[] bytes) {
        return hexToBigInteger(bytesToString(bytes));
    }

    public static String fromHex(String x) {
        if ( x.startsWith("0x") ) x = x.substring(2);
        if ( x.length() % 2 != 0 ) x = "0" + x;
        return x;
    }

    public static String toHex(String x) {
        if ( x.length() % 2 != 0 ) x = "0" + x;
        if ( !x.startsWith("0x") ) x = "0x" + x;
        return x;
    }

    /**
     * Stringify byte[] x
     * null for null
     * null for empty []
     */
    public static String toJsonHex(byte[] x) {
        return x == null || x.length == 0 ? null : "0x" + toHexString(x);
    }

    public static String toJsonHexNumber(byte[] x) {
        if ( x == null ) return "0x0";
        String hex = toHexString(x);
        return toJsonHex(hex.isEmpty() ? "0" : hex);
    }

    public static String toJsonHex(String x) {
        return "0x" + x;
    }

    public static String toJsonHex(int x) {
        return toJsonHex((long) x);
    }

    public static String toJsonHex(Long x) {
        return x == null ? null : "0x" + Long.toHexString(x);
    }

    public static String toJsonHex(BigInteger n) {
        return "0x" + n.toString(16);
    }

    public static String toHexString(byte[] bytes) {
        return BaseEncoding.base16().encode(bytes);
    }

    public static byte[] decodeUsingGuava(String hexString) {
        return BaseEncoding.base16().decode(hexString.toUpperCase());
    }

    public static String bytesToString(byte[] bytes) {
        return new String(bytes, StandardCharsets.UTF_8);
    }

}
