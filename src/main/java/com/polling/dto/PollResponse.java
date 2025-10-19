package com.polling.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PollResponse {
    private Long id;
    private String question;
    private String creatorUsername;
    private List<OptionResponse> options;
    private Long totalVotes;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    private boolean expired;
}
