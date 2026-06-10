package com.fooddonation.backend.service;

import com.fooddonation.backend.dto.UserAdminDTO;
import com.fooddonation.backend.dto.DashboardStatsDTO;
import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.entity.Food;
import com.fooddonation.backend.repository.FoodRepository;
import com.fooddonation.backend.repository.UserRepository;
import com.fooddonation.backend.repository.FoodClaimRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final FoodRepository foodRepository;
    private final FoodClaimRepository foodClaimRepository;

    public DashboardStatsDTO getDashboardStats() {
        long totalUsers = userRepository.count();
        // Online users are those active within the last 5 minutes
        long onlineUsers = userRepository.countByLastActiveAtAfter(LocalDateTime.now().minusMinutes(5));
        long totalFoods = foodRepository.count();

        List<Object[]> categoryCounts = foodRepository.countFoodsByCategory();
        Map<String, Long> categoryStats = new HashMap<>();
        
        // Initialize default categories to 0 so they show up on the chart even if empty
        categoryStats.put("makanan berat", 0L);
        categoryStats.put("minuman", 0L);
        categoryStats.put("sembako", 0L);
        categoryStats.put("kue snack", 0L);

        for (Object[] row : categoryCounts) {
            String category = (String) row[0];
            Long count = (Long) row[1];
            if (category != null && !category.trim().isEmpty()) {
                categoryStats.put(category.toLowerCase().trim(), count);
            }
        }

        return DashboardStatsDTO.builder()
                .totalUsers(totalUsers)
                .onlineUsers(onlineUsers)
                .totalFoods(totalFoods)
                .categoryStats(categoryStats)
                .build();
    }

    public List<UserAdminDTO> getAllUsersWithStats() {
        List<User> users = userRepository.findAll();
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME;

        return users.stream().map(user -> {
            long totalDonations = foodRepository.countByUserId(user.getId());
            long totalClaims = foodRepository.countByClaimedByAndStatus(user.getId(), "PICKED_UP");

            String timeoutStr = user.getTimeoutUntil() != null ? user.getTimeoutUntil().format(formatter) : null;
            String activeStr = user.getLastActiveAt() != null ? user.getLastActiveAt().format(formatter) : null;

            return UserAdminDTO.builder()
                    .id(user.getId())
                    .fullName(user.getFullName())
                    .email(user.getEmail())
                    .phone(user.getPhone())
                    .photoUrl(user.getPhotoUrl())
                    .role(user.getRole())
                    .isBanned(user.getIsBanned())
                    .timeoutUntil(timeoutStr)
                    .lastActiveAt(activeStr)
                    .totalDonations(totalDonations)
                    .totalClaims(totalClaims)
                    .build();
        }).collect(Collectors.toList());
    }

    public void banUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Toggle ban status
        boolean currentStatus = user.getIsBanned() != null ? user.getIsBanned() : false;
        user.setIsBanned(!currentStatus);
        
        userRepository.save(user);
    }

    public void timeoutUser(Long userId, int hours) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (hours <= 0) {
            // Remove timeout
            user.setTimeoutUntil(null);
        } else {
            user.setTimeoutUntil(LocalDateTime.now().plusHours(hours));
        }

        userRepository.save(user);
    }

    @Transactional
    public void deleteUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 1. Delete all claims by this user or for their donations
        foodClaimRepository.deleteByClaimerId(userId);
        foodClaimRepository.deleteByOwnerId(userId);

        // 2. Find all foods owned by this user and delete their claims, then delete the foods
        List<Food> userFoods = foodRepository.findByUserIdOrderByIdDesc(userId);
        for (Food food : userFoods) {
            foodClaimRepository.deleteByFoodId(food.getId());
        }
        foodRepository.deleteAll(userFoods);

        // 3. Finally delete the user
        userRepository.delete(user);
    }

    public List<Map<String, Object>> getAllFoodsAdmin() {
        List<Food> foods = foodRepository.findAll();
        
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME;
        
        return foods.stream().map(food -> {
            Map<String, Object> item = new HashMap<>();
            item.put("id", food.getId());
            item.put("food_name", food.getFoodName());
            item.put("description", food.getDescription());
            item.put("quantity", food.getQuantity());
            item.put("original_quantity", food.getOriginalQuantity() != null ? food.getOriginalQuantity() : food.getQuantity());
            item.put("status", food.getStatus() == null ? "POSTED" : food.getStatus());
            item.put("category", food.getCategory());
            item.put("food_condition", food.getFoodCondition());
            item.put("is_halal", food.getIsHalal());
            item.put("expired_at", food.getExpiredAt() != null ? food.getExpiredAt().format(formatter) : null);
            item.put("address", food.getAddress());
            item.put("user_id", food.getUser().getId());
            item.put("owner_name", food.getUser().getFullName());
            item.put("owner_phone", food.getPhone() != null && !food.getPhone().trim().isEmpty() ? food.getPhone().trim() : food.getUser().getPhone());
            return item;
        }).collect(Collectors.toList());
    }

    @Transactional
    public void deleteFoodAdmin(Long foodId) {
        Food food = foodRepository.findById(foodId)
                .orElseThrow(() -> new RuntimeException("Food not found"));
        
        foodClaimRepository.deleteByFoodId(foodId);
        foodRepository.delete(food);
    }
}
