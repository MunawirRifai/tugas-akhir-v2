package com.fooddonation.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import com.fooddonation.backend.service.AdminService;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

@SpringBootTest
class BackendApplicationTests {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Autowired
	private AdminService adminService;

	@Test
	void contextLoads() {
		try (FileWriter fw = new FileWriter("db_dump.log");
			 PrintWriter pw = new PrintWriter(fw)) {
			pw.println("=== FOOD CLAIMS ===");
			List<Map<String, Object>> claims = jdbcTemplate.queryForList("SELECT * FROM food_claims");
			for (Map<String, Object> claim : claims) {
				pw.println(claim);
			}
			pw.println("=== FOODS ===");
			List<Map<String, Object>> foods = jdbcTemplate.queryForList("SELECT id, food_name, status, claimed_by, claimed_quantity FROM foods");
			for (Map<String, Object> food : foods) {
				pw.println(food);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Test
	void updateSchema() {
		try {
			jdbcTemplate.execute("ALTER TABLE foods ADD COLUMN claimer_note VARCHAR(500) DEFAULT NULL");
			System.out.println("SCHEMA UPDATE SUCCESS FOR foods!");
		} catch (Exception e) {
			System.out.println("foods column might already exist: " + e.getMessage());
		}
		try {
			jdbcTemplate.execute("ALTER TABLE food_claims ADD COLUMN claimer_note VARCHAR(500) DEFAULT NULL");
			System.out.println("SCHEMA UPDATE SUCCESS FOR food_claims!");
		} catch (Exception e) {
			System.out.println("food_claims column might already exist: " + e.getMessage());
		}
	}

}

