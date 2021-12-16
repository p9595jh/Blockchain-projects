package com.hoon.iif.util;

import org.apache.commons.codec.binary.Hex;
import org.bouncycastle.asn1.ASN1Integer;
import org.bouncycastle.asn1.DEROctetString;
import org.bouncycastle.asn1.DERSequenceGenerator;
import org.hyperledger.fabric.protos.common.Common;
import org.hyperledger.fabric.sdk.security.CryptoSuite;

import java.io.ByteArrayOutputStream;

public class BlockConverter {

    public static String currentBlockhash(Common.BlockHeader blockHeader) {
        try {
            CryptoSuite cryptoSuite = CryptoSuite.Factory.getCryptoSuite();
            ByteArrayOutputStream s = new ByteArrayOutputStream();

            DERSequenceGenerator seq = new DERSequenceGenerator(s);
            seq.addObject(new ASN1Integer(blockHeader.getNumber()));
            seq.addObject(new DEROctetString(blockHeader.getPreviousHash().toByteArray()));
            seq.addObject(new DEROctetString(blockHeader.getDataHash().toByteArray()));
            seq.close();

            byte[] hash = cryptoSuite.hash(s.toByteArray());
            return Hex.encodeHexString(hash);

        } catch (Exception ignored) {}
        return "0x0";
    }
}
