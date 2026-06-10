package com.fooddonation.backend;

import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.crypto.password.PasswordEncoder;
import jakarta.annotation.PostConstruct;
import java.util.TimeZone;

@SpringBootApplication
@EnableScheduling
public class BackendApplication {

	public static void main(String[] args) {
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Jakarta"));
		SpringApplication.run(BackendApplication.class, args);
	}

	@Bean
	public CommandLineRunner createAdminUser(UserRepository userRepository, PasswordEncoder passwordEncoder) {
		return args -> {
			String email = "admin@email.com";
			if (!userRepository.existsByEmail(email)) {
				User admin = User.builder()
						.fullName("Super Admin")
						.email(email)
						.phone("081234567890")
						.password(passwordEncoder.encode("admin123"))
						.isVerified(true)
						.role("ROLE_ADMIN")
						.isBanned(false)
						.build();
				userRepository.save(admin);
				System.out.println("=== DUMMY ADMIN CREATED: email: admin@email.com, password: admin123 ===");
			} else {
				userRepository.findByEmail(email).ifPresent(admin -> {
					admin.setRole("ROLE_ADMIN");
					admin.setIsVerified(true);
					admin.setIsBanned(false);
					admin.setPassword(passwordEncoder.encode("admin123"));
					userRepository.save(admin);
					System.out.println("=== DUMMY ADMIN PASSWORD RESET TO: admin123 ===");
				});
			}
		};
	}
}
