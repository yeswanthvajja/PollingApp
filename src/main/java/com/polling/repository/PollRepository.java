package com.polling.repository;

import com.polling.entity.Poll;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PollRepository extends JpaRepository<Poll, Long> {
    
    @Query("SELECT DISTINCT p FROM Poll p LEFT JOIN FETCH p.options LEFT JOIN FETCH p.creator ORDER BY p.createdAt DESC")
    List<Poll> findAllWithOptionsAndCreator();
    
    @Query("SELECT DISTINCT p FROM Poll p LEFT JOIN FETCH p.options LEFT JOIN FETCH p.creator WHERE p.id = :id")
    Optional<Poll> findByIdWithOptionsAndCreator(@Param("id") Long id);
    
    @Query("SELECT DISTINCT p FROM Poll p LEFT JOIN FETCH p.options LEFT JOIN FETCH p.creator WHERE p.creator.id = :creatorId ORDER BY p.createdAt DESC")
    List<Poll> findByCreatorIdWithOptions(@Param("creatorId") Long creatorId);
    
    List<Poll> findByOrderByCreatedAtDesc();
    
    List<Poll> findByCreatorId(Long creatorId);
}
