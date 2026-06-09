package com.fooddonation.backend.service;

import com.fooddonation.backend.entity.Food;
import com.fooddonation.backend.entity.FoodClaim;
import com.fooddonation.backend.repository.FoodClaimRepository;
import com.fooddonation.backend.repository.FoodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FoodCleanupService {

    private final FoodRepository foodRepository;
    private final FoodClaimRepository foodClaimRepository;

    @Scheduled(fixedRate = 10000)
    @Transactional
    public void deleteExpiredFoods() {
        log.info("Running scheduled cleanup for expired foods at {}", LocalDateTime.now());
        List<Food> expiredFoods = foodRepository.findByExpiredAtBeforeAndStatusIn(
                LocalDateTime.now(),
                List.of("POSTED", "ON_THE_WAY")
        );

        if (!expiredFoods.isEmpty()) {
            log.info("Found {} expired food items to process", expiredFoods.size());
            for (Food food : expiredFoods) {
                log.info("Updating expired food to EXPIRED: id={}, name={}, expiredAt={}", food.getId(), food.getFoodName(), food.getExpiredAt());
                
                food.setStatus("EXPIRED");
                foodRepository.save(food);

                List<FoodClaim> claims = foodClaimRepository.findByFoodId(food.getId());
                if (!claims.isEmpty()) {
                    log.info("Updating {} claims associated with food id {} to EXPIRED", claims.size(), food.getId());
                    for (FoodClaim claim : claims) {
                        if ("ON_THE_WAY".equals(claim.getStatus())) {
                            claim.setStatus("EXPIRED");
                        }
                    }
                    foodClaimRepository.saveAll(claims);
                }
            }
        }
    }
}
