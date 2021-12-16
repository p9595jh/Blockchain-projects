package com.hoon.iif.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import org.codehaus.jackson.annotate.JsonProperty;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
@Entity
@Table(name = "ftcblock")
public class Block {

    @Id
    private String hash;

    private String prevHash;

    private Long number;

    @CreationTimestamp
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "created_at", updatable = false)
    @JsonProperty(value = "createdAt")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    private Date createdAt;
}
