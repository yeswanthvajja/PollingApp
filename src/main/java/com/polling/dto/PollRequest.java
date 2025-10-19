package com.polling.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class PollRequest {
    
    @NotBlank(message = "Question is required")
    @Size(max = 500, message = "Question must not exceed 500 characters")
    private String question;
    
    @NotEmpty(message = "At least two options are required")
    @Size(min = 2, max = 10, message = "Poll must have between 2 and 10 options")
    private List<String> options;
    
    private LocalDateTime expiresAt;
}
