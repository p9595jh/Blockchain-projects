package com.hoon.iif.util;

import com.hoon.iif.repository.AdminOperationRespository;
import com.hoon.iif.service.BlockService;
import org.hyperledger.fabric.gateway.*;
import org.hyperledger.fabric.sdk.BlockEvent;
import org.hyperledger.fabric.sdk.Enrollment;
import org.hyperledger.fabric.sdk.Peer;
import org.hyperledger.fabric.sdk.User;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.hyperledger.fabric.sdk.security.CryptoSuiteFactory;
import org.hyperledger.fabric_ca.sdk.EnrollmentRequest;
import org.hyperledger.fabric_ca.sdk.HFCAClient;
import org.hyperledger.fabric_ca.sdk.RegistrationRequest;
import org.hyperledger.fabric_ca.sdk.exception.RegistrationException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.File;
import java.net.URL;
import java.nio.file.Paths;
import java.security.PrivateKey;
import java.util.Optional;
import java.util.Properties;
import java.util.Set;
import java.util.function.Consumer;

@Component
public class Enroll {

    @Value("${fabric.ca.appUser.id}")
    private String userId;

    @Value("${fabric.ca.admin.user}")
    private String adminId;

    @Value("${fabric.ca.admin.secret}")
    private String adminSecret;

    @Value("${fabric.ca.admin.pemPath}")
    private String pem;

    @Value("${fabric.ca.admin.mspId}")
    private String msp;

    @Value("${fabric.ca.url}")
    private String caUrl;

    @Value("${fabric.ca.appUser.affiliation}")
    private String affiliation;

    @Value("${fabric.wallet.path}")
    private String walletPath;

    @Value("${fabric.network.configPath}")
    private String configPath;

    @Value("${fabric.networkName}")
    private String networkName;

    @Value("${fabric.contractName}")
    private String contractName;

    @Value("${fabric.service.discovery.asLocalhost}")
    private String asLocalhost;

    @Autowired
    private BlockService blockService;

    @Autowired
    private AdminOperationRespository adminOperationRespository;

    private Peer anyPeer;
    private long blockNumber;

    private void enrollAdmin() throws Exception {
        // Create a CA client for interacting with the CA.
        Properties props = new Properties();
        props.put("pemFile", pem);
        props.put("allowAllHostNames", "true");
        HFCAClient caClient = HFCAClient.createNewInstance(caUrl, props);
        CryptoSuite cryptoSuite = CryptoSuiteFactory.getDefault().getCryptoSuite();
        caClient.setCryptoSuite(cryptoSuite);

        // Create a wallet for managing identities
        Wallet wallet = Wallets.newFileSystemWallet(Paths.get(walletPath));

        // Check to see if we've already enrolled the admin user.
        if ( wallet.get(adminId) != null ) {
            System.out.printf("An identity for the admin user \"%s\" already exists in the wallet\n", adminId);
            System.exit(-1);
        }

        String caHost = new URL(caUrl).getHost();

        // Enroll the admin user, and import the new identity into the wallet.
        final EnrollmentRequest enrollmentRequestTLS = new EnrollmentRequest();
        enrollmentRequestTLS.addHost(caHost);
        enrollmentRequestTLS.setProfile("tls");
        Enrollment enrollment = caClient.enroll(adminId, adminSecret, enrollmentRequestTLS);
        Identity user = Identities.newX509Identity(msp, enrollment);
        wallet.put(adminId, user);
        System.out.printf("Successfully enrolled user \"%s\" and imported it into the wallet\n", adminId);
    }

    private void registerUser() throws Exception {
        // Create a CA client for interacting with the CA.
        Properties props = new Properties();
        props.put("pemFile", pem);
        props.put("allowAllHostNames", "true");
        HFCAClient caClient = HFCAClient.createNewInstance(caUrl, props);
        CryptoSuite cryptoSuite = CryptoSuiteFactory.getDefault().getCryptoSuite();
        caClient.setCryptoSuite(cryptoSuite);

        // Create a wallet for managing identities
        Wallet wallet = Wallets.newFileSystemWallet(Paths.get(walletPath));

        // Check to see if we've already enrolled the user.
        if ( wallet.get(userId) != null ) {
            System.out.printf("An identity for the user \"%s\" already exists in the wallet\n", userId);
            System.exit(-1);
        }

        X509Identity adminIdentity = (X509Identity)wallet.get("admin");
        if ( adminIdentity == null ) {
            System.out.printf("\"%s\" needs to be enrolled and added to the wallet first\n", adminId);
            System.exit(-1);
        }
        User admin = new User() {

            @Override
            public String getName() {
                return Enroll.this.adminId;
            }

            @Override
            public Set<String> getRoles() {
                return null;
            }

            @Override
            public String getAccount() {
                return null;
            }

            @Override
            public String getAffiliation() {
                return Enroll.this.affiliation;
            }

            @Override
            public Enrollment getEnrollment() {
                return new Enrollment() {

                    @Override
                    public PrivateKey getKey() {
                        return adminIdentity.getPrivateKey();
                    }

                    @Override
                    public String getCert() {
                        return Identities.toPemString(adminIdentity.getCertificate());
                    }
                };
            }

            @Override
            public String getMspId() {
                return Enroll.this.msp;
            }

        };

        // Register the user, enroll the user, and import the new identity into the wallet.
        RegistrationRequest registrationRequest = new RegistrationRequest(userId);
        registrationRequest.setAffiliation(affiliation);
        registrationRequest.setEnrollmentID(userId);
        String enrollmentSecret = caClient.register(registrationRequest, admin);
        Enrollment enrollment = caClient.enroll(userId, enrollmentSecret);
        Identity user = Identities.newX509Identity(msp, enrollment);
        wallet.put(userId, user);
    }

    public void doEnroll() throws Exception {
        try {
            File walletFolder = new File(walletPath);
            if ( walletFolder.exists() ) {
                for ( File f : walletFolder.listFiles() ) f.delete();
                walletFolder.delete();
            }

            enrollAdmin();
            registerUser();

        } catch (RegistrationException e) {
            System.out.println("already registered");
            System.out.println(e.getMessage());
            System.exit(-1);
        }
    }

    public void setConnection() throws Exception {
        Consumer<BlockEvent> blockListener = blockEvent -> blockNumber = blockService.processBlockEvent(blockEvent);
        Consumer<ContractEvent> contractListener = blockService::processContractEvent;

        try {
            // configure gateway, network, contract
            adminOperationRespository.init();

            Optional<Peer> anyPeerOptional = adminOperationRespository.getNetwork().getChannel().getPeers().stream().findAny();
            anyPeerOptional.ifPresent(peer -> anyPeer = peer);

            blockNumber = blockService.getLastBlockNumber();
            adminOperationRespository.getNetwork().addBlockListener(blockNumber, blockListener);
            adminOperationRespository.getContract().addContractListener(blockNumber, contractListener);

        } catch (Exception e) {
            e.printStackTrace();
            adminOperationRespository.getGateway().close();
        }
    }

    public String asLocalHost() {
        return asLocalhost;
    }

}
