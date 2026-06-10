package com.fooddonation.backend.controller;

import com.fooddonation.backend.dto.TimeoutRequest;
import com.fooddonation.backend.dto.UserAdminDTO;
import com.fooddonation.backend.dto.DashboardStatsDTO;
import com.fooddonation.backend.response.ApiResponse;
import com.fooddonation.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/dashboard-stats")
    public ResponseEntity<ApiResponse<DashboardStatsDTO>> getDashboardStats() {
        DashboardStatsDTO stats = adminService.getDashboardStats();
        return ResponseEntity.ok(
                ApiResponse.<DashboardStatsDTO>builder()
                        .success(true)
                        .message("Dashboard statistics loaded successfully")
                        .data(stats)
                        .build()
        );
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserAdminDTO>>> getAllUsers() {
        List<UserAdminDTO> users = adminService.getAllUsersWithStats();
        
        return ResponseEntity.ok(
                ApiResponse.<List<UserAdminDTO>>builder()
                        .success(true)
                        .message("Users loaded successfully")
                        .data(users)
                        .build()
        );
    }

    @PostMapping("/users/{id}/ban")
    public ResponseEntity<ApiResponse<String>> banUser(@PathVariable Long id) {
        adminService.banUser(id);
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("User ban status updated")
                        .data(null)
                        .build()
        );
    }

    @PostMapping("/users/{id}/timeout")
    public ResponseEntity<ApiResponse<String>> timeoutUser(
            @PathVariable Long id,
            @RequestBody TimeoutRequest request) {
        
        adminService.timeoutUser(id, request.getHours());
        
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("User timeout status updated")
                        .data(null)
                        .build()
        );
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<String>> deleteUser(@PathVariable Long id) {
        adminService.deleteUser(id);
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("User deleted successfully")
                        .data(null)
                        .build()
        );
    }

    @GetMapping("/foods")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllFoodsAdmin() {
        List<Map<String, Object>> foods = adminService.getAllFoodsAdmin();
        return ResponseEntity.ok(
                ApiResponse.<List<Map<String, Object>>>builder()
                        .success(true)
                        .message("All foods loaded successfully")
                        .data(foods)
                        .build()
        );
    }

    @DeleteMapping("/foods/{id}")
    public ResponseEntity<ApiResponse<String>> deleteFoodAdmin(@PathVariable Long id) {
        adminService.deleteFoodAdmin(id);
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("Food listing deleted successfully")
                        .data(null)
                        .build()
        );
    }
}
