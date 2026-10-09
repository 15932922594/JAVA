package com.fenglin.springboottest.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

/**
 * 密码工具：随机盐 + SHA-256 摘要
 * 与前端 src/store/accounts.js 的算法保持一致（sha256(salt + "::" + password) 的 hex 小写），
 * 即同一账号前端注册、后端校验结果一致。
 */
public final class PasswordUtil {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] HEX = "0123456789abcdef".toCharArray();

    private PasswordUtil() {
    }

    /** 生成 16 字节随机盐（32 位 hex 字符串） */
    public static String randomSalt() {
        byte[] bytes = new byte[16];
        RANDOM.nextBytes(bytes);
        return toHex(bytes);
    }

    /** 计算 SHA-256(salt::password) 的 hex 小写摘要 */
    public static String sha256(String salt, String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((salt + "::" + password).getBytes(StandardCharsets.UTF_8));
            return toHex(hash);
        } catch (NoSuchAlgorithmException e) {
            // JDK 必带 SHA-256，理论到不了这里
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    /** 校验密码是否与存储的摘要匹配 */
    public static boolean matches(String salt, String rawPassword, String storedHash) {
        return sha256(salt, rawPassword).equalsIgnoreCase(storedHash);
    }

    private static String toHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(HEX[(b >> 4) & 0xf]).append(HEX[b & 0xf]);
        }
        return sb.toString();
    }
}
