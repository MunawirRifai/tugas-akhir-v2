package com.fooddonation.backend.controller;

import com.fooddonation.backend.response.ApiResponse;
import com.fooddonation.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<?> getNotifications(Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Notifications loaded")
                        .data(notificationService.getNotifications(userId))
                        .build()
        );
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(
            @PathVariable Long id,
            Authentication authentication
    ) {
        Long userId = Long.parseLong(authentication.getName());
        notificationService.markAsRead(userId, id);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Notification marked as read")
                        .build()
        );
    }

    @PutMapping("/read-all")
    public ResponseEntity<?> markAllAsRead(Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        notificationService.markAllAsRead(userId);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Notifications marked as read")
                        .build()
        );
    }
}
