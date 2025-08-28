
package com.projectastra.financeservice.repository;

import com.projectastra.financeservice.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
}
