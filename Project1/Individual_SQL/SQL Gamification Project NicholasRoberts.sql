/* 
Case #001: The Vanishing Briefcase
Objective 1: Retrieve the correct crime scene details
*/

SELECT *
FROM crime_scene
WHERE location = 'Blue Note Lounge'
   OR description LIKE '%briefcase%'
   OR type LIKE '%theft%'
   OR type LIKE '%heist%';

/*
Objective 2: Identify the suspect whose profile matches the witness description
Witness clue: man in a trench coat
*/

SELECT *
FROM suspects
WHERE attire LIKE '%trench coat%';


/*
Case #002
Replace the clue values after reading the witness records
*/

WITH TargetCrimeScene AS (
    SELECT id, date, type, location, description
    FROM crime_scene
    WHERE location LIKE '%West Hollywood Records%'
       OR description LIKE '%record%'
       OR description LIKE '%vinyl%'
       OR type LIKE '%theft%'
),
WitnessClues AS (
    SELECT w.id, w.crime_scene_id, w.clue
    FROM witnesses w
    JOIN TargetCrimeScene c
        ON w.crime_scene_id = c.id
),
MatchingSuspects AS (
    SELECT *
    FROM suspects
    WHERE bandana_color LIKE '%[bandana color clue]%'
      AND accessory LIKE '%[accessory clue]%'
)
SELECT 
    ms.id,
    ms.name,
    ms.bandana_color,
    ms.accessory,
    i.transcript
FROM MatchingSuspects ms
JOIN interviews i
    ON ms.id = i.suspect_id;


    /*
Case #003
*/

WITH MarinaCrime AS (
    SELECT *
    FROM crime_scene
    WHERE location LIKE '%Coral Bay Marina%'
       OR description LIKE '%body%'
       OR description LIKE '%floating%'
       OR description LIKE '%murder%'
),
RelevantSurveillance AS (
    SELECT 
        p.id,
        p.name,
        p.alias,
        p.occupation,
        p.address,
        h.hotel_name,
        h.check_in_date,
        s.suspicious_activity
    FROM person p
    JOIN surveillance_records s
        ON p.id = s.person_id
    LEFT JOIN hotel_checkins h
        ON s.hotel_checkin_id = h.id
    WHERE s.suspicious_activity LIKE '%marina%'
       OR s.suspicious_activity LIKE '%dock%'
       OR s.suspicious_activity LIKE '%boat%'
       OR s.suspicious_activity LIKE '%blood%'
       OR s.suspicious_activity LIKE '%body%'
       OR s.suspicious_activity LIKE '%late%'
       OR s.suspicious_activity LIKE '%night%'
       OR s.suspicious_activity LIKE '%wet%'
       OR s.suspicious_activity LIKE '%argument%'
       OR s.suspicious_activity LIKE '%flee%'
),
InterviewClues AS (
    SELECT 
        p.id,
        p.name,
        i.transcript
    FROM person p
    JOIN interviews i
        ON p.id = i.person_id
    WHERE i.transcript LIKE '%marina%'
       OR i.transcript LIKE '%dock%'
       OR i.transcript LIKE '%boat%'
       OR i.transcript LIKE '%August 14%'
       OR i.transcript LIKE '%night%'
),
ConfessionMatch AS (
    SELECT 
        p.id,
        p.name,
        c.confession
    FROM person p
    JOIN confessions c
        ON p.id = c.person_id
    WHERE c.confession LIKE '%killed%'
       OR c.confession LIKE '%murder%'
       OR c.confession LIKE '%body%'
       OR c.confession LIKE '%marina%'
       OR c.confession LIKE '%I did it%'
)
SELECT 
    rs.id,
    rs.name,
    rs.alias,
    rs.occupation,
    rs.address,
    rs.hotel_name,
    rs.check_in_date,
    rs.suspicious_activity,
    ic.transcript,
    cm.confession
FROM RelevantSurveillance rs
LEFT JOIN InterviewClues ic
    ON rs.id = ic.id
LEFT JOIN ConfessionMatch cm
    ON rs.id = cm.id

    /* Case #006 */

WITH DiamondCrime AS (
    SELECT *
    FROM crime_scene
    WHERE location LIKE '%Fontainebleau%'
       OR description LIKE '%diamond%'
       OR description LIKE '%necklace%'
       OR description LIKE '%Heart of Atlantis%'
),
WitnessClues AS (
    SELECT 
        g.id,
        g.name,
        g.occupation,
        g.invitation_code,
        w.clue
    FROM guest g
    JOIN witness_statements w
        ON g.id = w.guest_id
),
AttireClues AS (
    SELECT 
        g.id,
        g.name,
        a.note
    FROM guest g
    JOIN attire_registry a
        ON g.id = a.guest_id
),
BoatAccess AS (
    SELECT 
        g.id,
        g.name,
        m.dock_number,
        m.rental_date,
        m.boat_name
    FROM guest g
    JOIN marina_rentals m
        ON g.id = m.renter_guest_id
),
ConfessionClues AS (
    SELECT 
        g.id,
        g.name,
        f.confession
    FROM guest g
    JOIN final_interviews f
        ON g.id = f.guest_id
)
SELECT 
    wc.id,
    wc.name,
    wc.occupation,
    wc.invitation_code,
    wc.clue,
    ac.note AS attire_note,
    ba.dock_number,
    ba.rental_date,
    ba.boat_name,
    cc.confession
FROM WitnessClues wc
LEFT JOIN AttireClues ac
    ON wc.id = ac.id
LEFT JOIN BoatAccess ba
    ON wc.id = ba.id
LEFT JOIN ConfessionClues cc
    ON wc.id = cc.id
WHERE wc.clue LIKE '%diamond%'
   OR wc.clue LIKE '%necklace%'
   OR wc.clue LIKE '%display%'
   OR wc.clue LIKE '%boat%'
   OR wc.clue LIKE '%dock%'
   OR ac.note IS NOT NULL
   OR ba.boat_name IS NOT NULL
   OR cc.confession IS NOT NULL;