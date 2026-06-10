package com.fooddonation.backend;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashTest {
    public static void main(String[] args) {
        System.out.println("HASH_OUTPUT:" + new BCryptPasswordEncoder().encode("admin123"));
    }
}
