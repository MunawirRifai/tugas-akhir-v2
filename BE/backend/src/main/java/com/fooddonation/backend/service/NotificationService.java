package com.fooddonation.backend.service;

import com.fooddonation.backend.entity.Food;
import com.fooddonation.backend.entity.Notification;
import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.repository.NotificationRepository;
import com.fooddonation.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public void notifyNewFood(Food food) {
        List<User> users = userRepository.findAll();

        List<Notification> notifications = users.stream()
                .filter(user -> !user.getId().equals(food.getUser().getId()))
                .map(user -> {
                    Notification notification = new Notification();
                    notification.setRecipientUserId(user.getId());
                    notification.setFoodId(food.getId());
                    notification.setTitle("Donasi makanan baru tersedia");
                    notification.setMessage(
                            food.getFoodName()
                                    + " baru saja diposting di "
                                    + food.getAddress()
                                    + ". Cek detailnya sebelum kedaluwarsa."
                    );
                    notification.setCategory("donation");
                    notification.setIsRead(false);
                    return notification;
                })
                .toList();

        if (!notifications.isEmpty()) {
            notificationRepository.saveAll(notifications);
        }
    }

    public void notifyClaimFood(Food food, User claimer) {
        Notification notification = new Notification();
        notification.setRecipientUserId(food.getUser().getId());
        notification.setFoodId(food.getId());

        String foodCat = food.getCategory() != null ? food.getCategory().toLowerCase().trim() : "makanan";
        if (!foodCat.equals("makanan") && !foodCat.equals("minuman")) {
            foodCat = "makanan";
        }

        notification.setTitle("Donasi Anda sedang diambil");
        notification.setMessage(
                claimer.getFullName()
                        + " sedang mengambil "
                        + foodCat
                        + " Anda (kontak: "
                        + claimer.getPhone()
                        + ")."
        );
        notification.setCategory("pickup");
        notification.setIsRead(false);

        notificationRepository.save(notification);
    }

    public void notifyCompletePickup(Food food, User claimer, String proofPhotoUrl) {
        Notification notification = new Notification();
        notification.setRecipientUserId(food.getUser().getId());
        notification.setFoodId(food.getId());

        String foodCat = food.getCategory() != null ? food.getCategory().toLowerCase().trim() : "makanan";
        if (!foodCat.equals("makanan") && !foodCat.equals("minuman")) {
            foodCat = "makanan";
        }

        notification.setTitle("Pengambilan selesai");
        notification.setMessage(
                claimer.getFullName()
                        + " telah selesai mengambil "
                        + foodCat
                        + " Anda ("
                        + food.getFoodName()
                        + ")."
        );
        notification.setCategory("proof");
        notification.setIsRead(false);

        notificationRepository.save(notification);
    }

    public List<Map<String, Object>> getNotifications(Long userId) {
        DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

        return notificationRepository.findByRecipientUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(notification -> Map.<String, Object>of(
                        "id", notification.getId(),
                        "title", notification.getTitle(),
                        "message", notification.getMessage(),
                        "category", notification.getCategory(),
                        "is_read", Boolean.TRUE.equals(notification.getIsRead()),
                        "created_at", notification.getCreatedAt() != null
                                ? notification.getCreatedAt().format(formatter)
                                : "",
                        "food_id", notification.getFoodId() != null
                                ? notification.getFoodId()
                                : ""
                ))
                .toList();
    }

    public void markAsRead(Long userId, Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("NOTIFICATION_NOT_FOUND"));

        if (!notification.getRecipientUserId().equals(userId)) {
            throw new RuntimeException("FORBIDDEN");
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    public void markAllAsRead(Long userId) {
        List<Notification> notifications =
                notificationRepository.findByRecipientUserIdAndIsReadFalse(userId);

        notifications.forEach(notification -> notification.setIsRead(true));
        notificationRepository.saveAll(notifications);
    }
}
