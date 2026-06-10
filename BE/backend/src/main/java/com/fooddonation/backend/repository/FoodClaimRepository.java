package com.fooddonation.backend.repository;

import com.fooddonation.backend.entity.FoodClaim;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FoodClaimRepository
        extends JpaRepository<FoodClaim, Long> {

    List<FoodClaim>
    findByClaimerIdOrderByClaimedAtDesc(
            Long claimerId
    );

    List<FoodClaim>
    findByOwnerIdOrderByClaimedAtDesc(
            Long ownerId
    );

    List<FoodClaim> findByFoodId(Long foodId);

    void deleteByClaimerId(Long claimerId);

    void deleteByOwnerId(Long ownerId);

    void deleteByFoodId(Long foodId);
}