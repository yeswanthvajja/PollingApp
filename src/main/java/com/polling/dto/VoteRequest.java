package com.polling.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class VoteRequest {
    
    @NotNull(message = "Option ID is required")
    private Long optionId;
}
