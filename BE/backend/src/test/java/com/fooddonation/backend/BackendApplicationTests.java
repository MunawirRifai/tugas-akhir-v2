package com.fooddonation.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

@SpringBootTest
class BackendApplicationTests {

	@Autowired
	private JdbcTemplate jdbcTemplate;

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

}
