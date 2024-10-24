module MyModule::TutoringMarketplace {

    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;  // Import the vector module from the standard library

    /// Struct representing a tutoring session.
    struct TutoringSession has key, store {
        tutor: address,    // Tutor's address
        price: u64,        // Price per session
        is_booked: bool,   // Flag to check if the session is already booked
    }

    /// Struct to store multiple sessions for a tutor.
    struct TutorSessions has key, store {
        sessions: vector::Vector<TutoringSession>,  // Using the vector type correctly
    }

    /// Function to initialize the tutor's account with session storage.
    public fun init_tutor_account(tutor: &signer) {
        let tutor_address = signer::address_of(tutor);
        move_to(tutor, TutorSessions { sessions: vector::empty<TutoringSession>() });
    }

    /// Function to create a new tutoring session with a price.
    public fun create_session(tutor: &signer, price: u64) acquires TutorSessions {
        let tutor_address = signer::address_of(tutor);

        // Ensure the tutor has session storage initialized.
        let sessions = borrow_global_mut<TutorSessions>(tutor_address);

        // Create a new session and add it to the tutor's session list.
        let new_session = TutoringSession {
            tutor: tutor_address,
            price,
            is_booked: false,
        };

        // Correctly pushing new session
        vector::push_back(&mut sessions.sessions, new_session);
    }

    /// Function for a student to book a session by paying the tutor.
    public fun book_session(student: &signer, tutor_address: address, amount: u64) acquires TutorSessions {
        let sessions = borrow_global_mut<TutorSessions>(tutor_address);

        // Find an unbooked session
        let session_count = vector::length(&sessions.sessions);  // Getting the session count
        let mut i = 0;  // Mutable index
        let mut found = false;  // Mutable flag to indicate if a session is found

        while (i < session_count) {
            // Borrowing mutable reference
            let session_ref = vector::borrow_mut(&mut sessions.sessions, i);  
            if (!session_ref.is_booked && session_ref.price == amount) {
                // Book this session and transfer payment
                session_ref.is_booked = true;
                found = true;

                // Withdraw and deposit coins
                let payment = coin::withdraw<AptosCoin>(student, amount);
                coin::deposit<AptosCoin>(session_ref.tutor, payment);
                break; // Exit loop once session is booked
            }
            i = i + 1;  // Increment the index
        }

        // Check if a suitable session was found
        assert!(found, "No suitable session found.");  // More descriptive error message
    }
}
