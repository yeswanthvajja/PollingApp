package com.polling.controller;

import com.polling.dto.PollRequest;
import com.polling.dto.PollResponse;
import com.polling.dto.OptionResponse;
import com.polling.service.PollService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PollControllerTest {

    @Mock
    private PollService pollService;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private PollController pollController;

    private PollRequest pollRequest;
    private PollResponse pollResponse;

    @BeforeEach
    void setUp() {
        // Setup test data
        pollRequest = new PollRequest();
        pollRequest.setQuestion("What is your favorite color?");
        pollRequest.setOptions(Arrays.asList("Red", "Blue", "Green"));
        pollRequest.setExpiresAt(LocalDateTime.now().plusDays(7));

        // Setup poll response
        OptionResponse option1 = new OptionResponse(1L, "Red", 5L);
        OptionResponse option2 = new OptionResponse(2L, "Blue", 3L);
        OptionResponse option3 = new OptionResponse(3L, "Green", 2L);

        pollResponse = new PollResponse(
                1L,
                "What is your favorite color?",
                "testuser",
                Arrays.asList(option1, option2, option3),
                10L,
                LocalDateTime.now(),
                LocalDateTime.now().plusDays(7),
                false
        );

        // Mock authentication
        when(authentication.getName()).thenReturn("testuser");
    }

    @Test
    void testCreatePoll_Success() {
        // Arrange
        when(pollService.createPoll(any(PollRequest.class), anyString()))
                .thenReturn(pollResponse);

        // Act
        ResponseEntity<?> response = pollController.createPoll(pollRequest, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody() instanceof PollResponse);

        PollResponse actualResponse = (PollResponse) response.getBody();
        assertEquals(1L, actualResponse.getId());
        assertEquals("What is your favorite color?", actualResponse.getQuestion());
        assertEquals("testuser", actualResponse.getCreatorUsername());

        verify(pollService, times(1)).createPoll(any(PollRequest.class), eq("testuser"));
        verify(authentication, times(1)).getName();
    }

    @Test
    void testGetAllPolls_Success() {
        // Arrange
        PollResponse pollResponse2 = new PollResponse(
                2L,
                "Favorite programming language?",
                "testuser2",
                Arrays.asList(new OptionResponse(4L, "Java", 8L)),
                8L,
                LocalDateTime.now(),
                LocalDateTime.now().plusDays(7),
                false
        );

        List<PollResponse> pollResponses = Arrays.asList(pollResponse, pollResponse2);

        when(pollService.getAllPolls()).thenReturn(pollResponses);

        // Act
        ResponseEntity<List<PollResponse>> response = pollController.getAllPolls();

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());

        List<PollResponse> actualResponses = response.getBody();
        assertEquals(2, actualResponses.size());
        assertEquals("What is your favorite color?", actualResponses.get(0).getQuestion());
        assertEquals("Favorite programming language?", actualResponses.get(1).getQuestion());

        verify(pollService, times(1)).getAllPolls();
    }

    @Test
    void testGetPollById_Success() {
        // Arrange
        Long pollId = 1L;
        when(pollService.getPollById(pollId)).thenReturn(pollResponse);

        // Act
        ResponseEntity<?> response = pollController.getPollById(pollId);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody() instanceof PollResponse);

        PollResponse actualResponse = (PollResponse) response.getBody();
        assertEquals(pollId, actualResponse.getId());
        assertEquals("What is your favorite color?", actualResponse.getQuestion());

        verify(pollService, times(1)).getPollById(pollId);
    }

    @Test
    void testGetPollById_NotFound() {
        // Arrange
        Long pollId = 999L;
        when(pollService.getPollById(pollId))
                .thenThrow(new RuntimeException("Poll not found"));

        // Act
        ResponseEntity<?> response = pollController.getPollById(pollId);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());

        verify(pollService, times(1)).getPollById(pollId);
    }

    @Test
    void testGetUserPolls_Success() {
        // Arrange
        List<PollResponse> userPolls = Arrays.asList(pollResponse);
        when(pollService.getPollsByUser("testuser")).thenReturn(userPolls);

        // Act
        ResponseEntity<?> response = pollController.getUserPolls(authentication);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody() instanceof List);

        @SuppressWarnings("unchecked")
        List<PollResponse> actualResponses = (List<PollResponse>) response.getBody();
        assertEquals(1, actualResponses.size());
        assertEquals("testuser", actualResponses.get(0).getCreatorUsername());

        verify(pollService, times(1)).getPollsByUser("testuser");
        verify(authentication, times(1)).getName();
    }

    @Test
    void testCreatePoll_WithException() {
        // Arrange
        when(pollService.createPoll(any(PollRequest.class), anyString()))
                .thenThrow(new RuntimeException("User not found"));

        // Act
        ResponseEntity<?> response = pollController.createPoll(pollRequest, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());

        verify(pollService, times(1)).createPoll(any(PollRequest.class), anyString());
    }
}
