package com.fooddonation.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "food_claims")
@Getter
@Setter
public class FoodClaim {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "food_id", nullable = false)
    private Long foodId;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "claimer_id", nullable = false)
    private Long claimerId;

    @Column(name = "claimed_quantity", nullable = false)
    private Integer claimedQuantity;

    @Column(name = "status")
    private String status;

    @Column(name = "claimed_at")
    private LocalDateTime claimedAt = LocalDateTime.now();

    @Column(name = "completed_at")
    private LocalDateTime completedAt;
}