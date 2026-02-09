--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-11-27 22:43:21

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 16874)
-- Name: rayscan; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA rayscan;


ALTER SCHEMA rayscan OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16389)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 271 (class 1255 OID 16741)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 246 (class 1259 OID 16724)
-- Name: admin_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_logs (
    id integer NOT NULL,
    admin_id integer NOT NULL,
    action character varying(100) NOT NULL,
    target_table character varying(50),
    target_id integer,
    details jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_logs OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16723)
-- Name: admin_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 245
-- Name: admin_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_logs_id_seq OWNED BY public.admin_logs.id;


--
-- TOC entry 230 (class 1259 OID 16512)
-- Name: ai_diagnoses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ai_diagnoses (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    diagnosis_result character varying(20) NOT NULL,
    condition_detected character varying(255),
    confidence_percentage numeric(5,2),
    ai_model_version character varying(50),
    detection_details jsonb,
    processed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ai_diagnoses_diagnosis_result_check CHECK (((diagnosis_result)::text = ANY ((ARRAY['normal'::character varying, 'abnormal'::character varying, 'suspicious'::character varying])::text[])))
);


ALTER TABLE public.ai_diagnoses OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16511)
-- Name: ai_diagnoses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ai_diagnoses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ai_diagnoses_id_seq OWNER TO postgres;

--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 229
-- Name: ai_diagnoses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ai_diagnoses_id_seq OWNED BY public.ai_diagnoses.id;


--
-- TOC entry 236 (class 1259 OID 16583)
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    appointment_date date NOT NULL,
    appointment_time time without time zone NOT NULL,
    appointment_type character varying(20) DEFAULT 'consultation'::character varying,
    consultation_mode character varying(20) DEFAULT 'video_call'::character varying,
    status character varying(20) DEFAULT 'scheduled'::character varying,
    reason_for_visit text,
    consultation_fee numeric(10,2),
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT appointments_appointment_type_check CHECK (((appointment_type)::text = ANY ((ARRAY['consultation'::character varying, 'follow_up'::character varying, 'emergency'::character varying])::text[]))),
    CONSTRAINT appointments_consultation_mode_check CHECK (((consultation_mode)::text = ANY ((ARRAY['video_call'::character varying, 'in_person'::character varying, 'chat'::character varying])::text[]))),
    CONSTRAINT appointments_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying, 'refunded'::character varying])::text[]))),
    CONSTRAINT appointments_status_check CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'confirmed'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'no_show'::character varying])::text[])))
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16582)
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_id_seq OWNER TO postgres;

--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 235
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- TOC entry 260 (class 1259 OID 25072)
-- Name: call_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_logs (
    id integer NOT NULL,
    conversation_id integer,
    caller_user_id integer NOT NULL,
    receiver_user_id integer NOT NULL,
    call_type character varying(10) NOT NULL,
    status character varying(20) DEFAULT 'initiated'::character varying,
    channel_name character varying(255),
    duration integer DEFAULT 0,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT call_logs_call_type_check CHECK (((call_type)::text = ANY ((ARRAY['audio'::character varying, 'video'::character varying])::text[]))),
    CONSTRAINT call_logs_status_check CHECK (((status)::text = ANY ((ARRAY['initiated'::character varying, 'ringing'::character varying, 'answered'::character varying, 'missed'::character varying, 'rejected'::character varying, 'ended'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.call_logs OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 25071)
-- Name: call_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.call_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 259
-- Name: call_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_logs_id_seq OWNED BY public.call_logs.id;


--
-- TOC entry 240 (class 1259 OID 16644)
-- Name: consultations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consultations (
    id integer NOT NULL,
    appointment_id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    consultation_notes text,
    prescription text,
    follow_up_required boolean DEFAULT false,
    follow_up_date date,
    consultation_rating integer,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    CONSTRAINT consultations_consultation_rating_check CHECK (((consultation_rating >= 1) AND (consultation_rating <= 5)))
);


ALTER TABLE public.consultations OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16643)
-- Name: consultations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.consultations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.consultations_id_seq OWNER TO postgres;

--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 239
-- Name: consultations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.consultations_id_seq OWNED BY public.consultations.id;


--
-- TOC entry 248 (class 1259 OID 16751)
-- Name: conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    doctor_id integer NOT NULL,
    type character varying(20) DEFAULT 'consultation'::character varying,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    doctor_user_id integer,
    CONSTRAINT conversations_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'closed'::character varying])::text[]))),
    CONSTRAINT conversations_type_check CHECK (((type)::text = ANY ((ARRAY['consultation'::character varying, 'follow_up'::character varying])::text[])))
);


ALTER TABLE public.conversations OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16750)
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conversations_id_seq OWNER TO postgres;

--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 247
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- TOC entry 234 (class 1259 OID 16566)
-- Name: doctor_availability; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctor_availability (
    id integer NOT NULL,
    doctor_id integer NOT NULL,
    day_of_week character varying(10) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_active boolean DEFAULT true,
    CONSTRAINT doctor_availability_day_of_week_check CHECK (((day_of_week)::text = ANY ((ARRAY['Monday'::character varying, 'Tuesday'::character varying, 'Wednesday'::character varying, 'Thursday'::character varying, 'Friday'::character varying, 'Saturday'::character varying, 'Sunday'::character varying])::text[])))
);


ALTER TABLE public.doctor_availability OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16565)
-- Name: doctor_availability_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctor_availability_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doctor_availability_id_seq OWNER TO postgres;

--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 233
-- Name: doctor_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctor_availability_id_seq OWNED BY public.doctor_availability.id;


--
-- TOC entry 224 (class 1259 OID 16440)
-- Name: doctors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    pmdc_number character varying(50) NOT NULL,
    specialization character varying(255) NOT NULL,
    qualification character varying(500),
    experience_years integer DEFAULT 0,
    consultation_fee numeric(10,2) DEFAULT 0.00,
    clinic_address text,
    clinic_phone character varying(20),
    bio text,
    rating numeric(3,2) DEFAULT 0.00,
    total_reviews integer DEFAULT 0,
    is_pmdc_verified boolean DEFAULT false,
    availability_status character varying(20) DEFAULT 'offline'::character varying,
    full_name character varying(100),
    profile_image_url character varying(255),
    CONSTRAINT doctors_availability_status_check CHECK (((availability_status)::text = ANY ((ARRAY['available'::character varying, 'busy'::character varying, 'offline'::character varying])::text[])))
);


ALTER TABLE public.doctors OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16439)
-- Name: doctors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.doctors_id_seq OWNER TO postgres;

--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 223
-- Name: doctors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctors_id_seq OWNED BY public.doctors.id;


--
-- TOC entry 250 (class 1259 OID 16774)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    sender_id integer NOT NULL,
    sender_type character varying(10) NOT NULL,
    message_type character varying(10) DEFAULT 'text'::character varying,
    content text,
    file_url character varying(255),
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT messages_message_type_check CHECK (((message_type)::text = ANY ((ARRAY['text'::character varying, 'image'::character varying, 'file'::character varying, 'audio'::character varying, 'video'::character varying])::text[]))),
    CONSTRAINT messages_sender_type_check CHECK (((sender_type)::text = ANY ((ARRAY['user'::character varying, 'doctor'::character varying])::text[])))
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16773)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 249
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- TOC entry 242 (class 1259 OID 16675)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    notification_type character varying(50) NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16674)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 241
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 256 (class 1259 OID 16834)
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token character varying(6) NOT NULL,
    contact_info character varying(100) NOT NULL,
    contact_type character varying(10) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    is_used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT password_reset_tokens_contact_type_check CHECK (((contact_type)::text = ANY ((ARRAY['email'::character varying, 'phone'::character varying])::text[])))
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 16833)
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_reset_tokens_id_seq OWNER TO postgres;

--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 255
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- TOC entry 222 (class 1259 OID 16422)
-- Name: patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patients (
    id integer NOT NULL,
    user_id integer NOT NULL,
    emergency_contact character varying(20),
    blood_group character varying(5),
    medical_history text,
    allergies text,
    current_medications text,
    insurance_provider character varying(255),
    insurance_number character varying(100),
    CONSTRAINT patients_blood_group_check CHECK (((blood_group)::text = ANY ((ARRAY['A+'::character varying, 'A-'::character varying, 'B+'::character varying, 'B-'::character varying, 'AB+'::character varying, 'AB-'::character varying, 'O+'::character varying, 'O-'::character varying])::text[])))
);


ALTER TABLE public.patients OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16421)
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.patients_id_seq OWNER TO postgres;

--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 221
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patients_id_seq OWNED BY public.patients.id;


--
-- TOC entry 238 (class 1259 OID 16616)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    appointment_id integer,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    transaction_id character varying(255),
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    payment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    refund_amount numeric(10,2),
    refund_date timestamp without time zone,
    CONSTRAINT payments_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'refunded'::character varying])::text[])))
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16615)
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO postgres;

--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 237
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- TOC entry 226 (class 1259 OID 16469)
-- Name: pharmacies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pharmacies (
    id integer NOT NULL,
    user_id integer NOT NULL,
    pharmacy_name character varying(255) NOT NULL,
    license_number character varying(100) NOT NULL,
    owner_name character varying(255),
    pharmacy_address text NOT NULL,
    pharmacy_phone character varying(20),
    operating_hours character varying(255),
    delivery_available boolean DEFAULT false,
    latitude numeric(10,8),
    longitude numeric(11,8)
);


ALTER TABLE public.pharmacies OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16468)
-- Name: pharmacies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pharmacies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pharmacies_id_seq OWNER TO postgres;

--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 225
-- Name: pharmacies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pharmacies_id_seq OWNED BY public.pharmacies.id;


--
-- TOC entry 254 (class 1259 OID 16819)
-- Name: pharmacy_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pharmacy_products (
    id integer NOT NULL,
    pharmacy_id integer NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50) NOT NULL,
    price numeric(10,2),
    in_stock boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pharmacy_products_category_check CHECK (((category)::text = ANY ((ARRAY['covid19'::character varying, 'blood_pressure'::character varying, 'pain_killers'::character varying, 'stomach'::character varying, 'epiapcy'::character varying, 'pancreatics'::character varying, 'nuero_pill'::character varying, 'immune_system'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE public.pharmacy_products OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 16818)
-- Name: pharmacy_products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pharmacy_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pharmacy_products_id_seq OWNER TO postgres;

--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 253
-- Name: pharmacy_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pharmacy_products_id_seq OWNED BY public.pharmacy_products.id;


--
-- TOC entry 232 (class 1259 OID 16532)
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer,
    report_type character varying(20) DEFAULT 'ai_generated'::character varying,
    diagnosis text NOT NULL,
    recommendations text,
    severity_level character varying(20),
    report_pdf_path character varying(500),
    is_verified boolean DEFAULT false,
    verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reports_report_type_check CHECK (((report_type)::text = ANY ((ARRAY['ai_generated'::character varying, 'doctor_verified'::character varying, 'final'::character varying])::text[]))),
    CONSTRAINT reports_severity_level_check CHECK (((severity_level)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'critical'::character varying])::text[])))
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16531)
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reports_id_seq OWNER TO postgres;

--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 231
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- TOC entry 244 (class 1259 OID 16694)
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    appointment_id integer,
    rating integer NOT NULL,
    review_text text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16693)
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO postgres;

--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 243
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- TOC entry 228 (class 1259 OID 16490)
-- Name: scans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scans (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    scan_type character varying(20) NOT NULL,
    image_path character varying(500) NOT NULL,
    original_filename character varying(255),
    file_size integer,
    upload_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    scan_status character varying(20) DEFAULT 'uploaded'::character varying,
    ai_confidence_score numeric(5,4),
    processing_time_seconds integer,
    CONSTRAINT scans_scan_status_check CHECK (((scan_status)::text = ANY ((ARRAY['uploaded'::character varying, 'processing'::character varying, 'analyzed'::character varying, 'verified'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT scans_scan_type_check CHECK (((scan_type)::text = ANY ((ARRAY['kidney'::character varying, 'breast'::character varying])::text[])))
);


ALTER TABLE public.scans OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16489)
-- Name: scans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scans_id_seq OWNER TO postgres;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 227
-- Name: scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scans_id_seq OWNED BY public.scans.id;


--
-- TOC entry 252 (class 1259 OID 16793)
-- Name: ultrasound_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ultrasound_reports (
    id integer NOT NULL,
    user_id integer NOT NULL,
    scan_type character varying(20) NOT NULL,
    image_url character varying(255) NOT NULL,
    ai_analysis text,
    result character varying(20),
    confidence_score numeric(3,2),
    recommended_doctor_id integer,
    status character varying(20) DEFAULT 'processing'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ultrasound_reports_result_check CHECK (((result)::text = ANY ((ARRAY['normal'::character varying, 'abnormal'::character varying, 'detected'::character varying, 'not_detected'::character varying])::text[]))),
    CONSTRAINT ultrasound_reports_scan_type_check CHECK (((scan_type)::text = ANY ((ARRAY['kidney'::character varying, 'breast'::character varying])::text[]))),
    CONSTRAINT ultrasound_reports_status_check CHECK (((status)::text = ANY ((ARRAY['processing'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.ultrasound_reports OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16792)
-- Name: ultrasound_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ultrasound_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ultrasound_reports_id_seq OWNER TO postgres;

--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 251
-- Name: ultrasound_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ultrasound_reports_id_seq OWNED BY public.ultrasound_reports.id;


--
-- TOC entry 258 (class 1259 OID 16849)
-- Name: user_health_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_health_metrics (
    id integer NOT NULL,
    user_id integer NOT NULL,
    heart_rate integer,
    calories_burned integer,
    weight numeric(5,2),
    height numeric(5,2),
    blood_pressure_systolic integer,
    blood_pressure_diastolic integer,
    recorded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_health_metrics OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 16848)
-- Name: user_health_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_health_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_health_metrics_id_seq OWNER TO postgres;

--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 257
-- Name: user_health_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_health_metrics_id_seq OWNED BY public.user_health_metrics.id;


--
-- TOC entry 220 (class 1259 OID 16401)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(20),
    full_name character varying(255) NOT NULL,
    date_of_birth date,
    gender character varying(10),
    address text,
    city character varying(100),
    country character varying(100) DEFAULT 'Pakistan'::character varying,
    role character varying(20) NOT NULL,
    profile_image character varying(500),
    is_active boolean DEFAULT true,
    is_verified boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_gender_check CHECK (((gender)::text = ANY ((ARRAY['Male'::character varying, 'Female'::character varying, 'Other'::character varying])::text[]))),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['patient'::character varying, 'doctor'::character varying, 'admin'::character varying, 'pharmacy'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16400)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 219
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4799 (class 2604 OID 16727)
-- Name: admin_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_logs ALTER COLUMN id SET DEFAULT nextval('public.admin_logs_id_seq'::regclass);


--
-- TOC entry 4773 (class 2604 OID 16515)
-- Name: ai_diagnoses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_diagnoses ALTER COLUMN id SET DEFAULT nextval('public.ai_diagnoses_id_seq'::regclass);


--
-- TOC entry 4782 (class 2604 OID 16586)
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- TOC entry 4822 (class 2604 OID 25075)
-- Name: call_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_logs ALTER COLUMN id SET DEFAULT nextval('public.call_logs_id_seq'::regclass);


--
-- TOC entry 4792 (class 2604 OID 16647)
-- Name: consultations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations ALTER COLUMN id SET DEFAULT nextval('public.consultations_id_seq'::regclass);


--
-- TOC entry 4801 (class 2604 OID 16754)
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- TOC entry 4780 (class 2604 OID 16569)
-- Name: doctor_availability id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability ALTER COLUMN id SET DEFAULT nextval('public.doctor_availability_id_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 16443)
-- Name: doctors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors ALTER COLUMN id SET DEFAULT nextval('public.doctors_id_seq'::regclass);


--
-- TOC entry 4806 (class 2604 OID 16777)
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- TOC entry 4794 (class 2604 OID 16678)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 4817 (class 2604 OID 16837)
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- TOC entry 4760 (class 2604 OID 16425)
-- Name: patients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients ALTER COLUMN id SET DEFAULT nextval('public.patients_id_seq'::regclass);


--
-- TOC entry 4789 (class 2604 OID 16619)
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- TOC entry 4768 (class 2604 OID 16472)
-- Name: pharmacies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacies ALTER COLUMN id SET DEFAULT nextval('public.pharmacies_id_seq'::regclass);


--
-- TOC entry 4814 (class 2604 OID 16822)
-- Name: pharmacy_products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacy_products ALTER COLUMN id SET DEFAULT nextval('public.pharmacy_products_id_seq'::regclass);


--
-- TOC entry 4775 (class 2604 OID 16535)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 4797 (class 2604 OID 16697)
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- TOC entry 4770 (class 2604 OID 16493)
-- Name: scans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans ALTER COLUMN id SET DEFAULT nextval('public.scans_id_seq'::regclass);


--
-- TOC entry 4810 (class 2604 OID 16796)
-- Name: ultrasound_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ultrasound_reports ALTER COLUMN id SET DEFAULT nextval('public.ultrasound_reports_id_seq'::regclass);


--
-- TOC entry 4820 (class 2604 OID 16852)
-- Name: user_health_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_health_metrics ALTER COLUMN id SET DEFAULT nextval('public.user_health_metrics_id_seq'::regclass);


--
-- TOC entry 4754 (class 2604 OID 16404)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 5173 (class 0 OID 16724)
-- Dependencies: 246
-- Data for Name: admin_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_logs (id, admin_id, action, target_table, target_id, details, created_at) FROM stdin;
\.


--
-- TOC entry 5157 (class 0 OID 16512)
-- Dependencies: 230
-- Data for Name: ai_diagnoses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_diagnoses (id, scan_id, diagnosis_result, condition_detected, confidence_percentage, ai_model_version, detection_details, processed_at) FROM stdin;
\.


--
-- TOC entry 5163 (class 0 OID 16583)
-- Dependencies: 236
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (id, patient_id, doctor_id, appointment_date, appointment_time, appointment_type, consultation_mode, status, reason_for_visit, consultation_fee, payment_status, notes, created_at, updated_at) FROM stdin;
20	3	2	2025-09-29	09:00:00	consultation	video_call	scheduled	uh	120.00	pending	\N	2025-09-28 13:35:01.069191	2025-09-28 13:35:01.069191
21	2	2	2025-01-15	10:00:00	consultation	video_call	scheduled	Heart checkup consultation	120.00	pending	\N	2025-09-28 13:35:58.623055	2025-09-28 13:35:58.623055
23	3	2	2025-09-29	09:30:00	consultation	video_call	scheduled	dhd	120.00	pending	\N	2025-09-28 13:45:16.627901	2025-09-28 13:45:16.627901
24	4	2	2024-09-30	10:00:00	consultation	video_call	cancelled	Test appointment for cancellation	120.00	pending	\nCancellation reason: Change of plans - testing cancellation	2025-09-28 13:56:34.034835	2025-09-28 13:56:42.77713
22	3	2	2025-09-29	10:00:00	consultation	video_call	cancelled	jfsuj	120.00	pending	\nCancellation reason: Cancelled by patient	2025-09-28 13:36:17.403006	2025-09-28 17:34:01.661795
26	6	6	2025-10-01	11:00:00	consultation	video_call	scheduled	headache	140.00	pending	\N	2025-09-30 14:55:16.335716	2025-09-30 14:55:16.335716
29	7	9	2025-10-20	11:30:00	consultation	video_call	scheduled	dddd	0.00	pending	\N	2025-10-16 03:45:57.67095	2025-10-16 03:45:57.67095
27	7	9	2025-10-20	12:30:00	consultation	video_call	cancelled	ddd	0.00	pending	yes\n\nCancelled by doctor: sss	2025-10-16 00:50:28.551234	2025-10-16 03:47:20.116094
30	7	9	2025-10-20	12:30:00	consultation	video_call	completed	yo	0.00	pending	sss\n\nsss	2025-10-16 09:47:24.639896	2025-10-16 09:50:16.976128
28	7	9	2025-10-20	12:00:00	consultation	video_call	cancelled	yoyo	0.00	pending	\nCancellation reason: Cancelled by patient	2025-10-16 03:21:57.148221	2025-10-16 09:51:53.27736
31	7	9	2025-10-22	11:50:00	consultation	video_call	scheduled	yes	0.00	pending	\N	2025-10-16 12:04:20.176767	2025-10-16 12:04:20.176767
33	8	10	2025-11-06	17:00:00	consultation	video_call	completed	bro very pain	0.00	pending	swwssss\n\nssss	2025-11-06 16:56:19.601526	2025-11-06 19:26:03.802541
32	8	10	2025-11-10	01:30:00	consultation	video_call	confirmed	bro	0.00	pending	\N	2025-11-06 16:49:11.316781	2025-11-06 23:59:13.029176
\.


--
-- TOC entry 5187 (class 0 OID 25072)
-- Dependencies: 260
-- Data for Name: call_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.call_logs (id, conversation_id, caller_user_id, receiver_user_id, call_type, status, channel_name, duration, started_at, ended_at, created_at, updated_at) FROM stdin;
1	3	21	10	audio	missed	rayscan-conv3	0	2025-11-21 02:04:45.675253	2025-11-21 02:04:45.736662	2025-11-21 02:04:45.675253	2025-11-21 02:04:45.675253
2	3	21	10	video	missed	rayscan-conv3	0	2025-11-21 02:04:54.856164	2025-11-21 02:04:54.857845	2025-11-21 02:04:54.856164	2025-11-21 02:04:54.856164
3	3	22	21	audio	missed	rayscan-conv3	0	2025-11-21 02:13:30.816552	2025-11-21 02:13:30.871482	2025-11-21 02:13:30.816552	2025-11-21 02:13:30.816552
4	3	22	21	video	missed	rayscan-conv3	0	2025-11-21 02:13:38.477802	2025-11-21 02:13:38.48682	2025-11-21 02:13:38.477802	2025-11-21 02:13:38.477802
5	3	21	22	audio	missed	rayscan-conv3	0	2025-11-21 10:11:25.644425	2025-11-21 10:11:25.654183	2025-11-21 10:11:25.644425	2025-11-21 10:11:25.644425
6	3	21	22	video	missed	rayscan-conv3	0	2025-11-21 10:11:35.910429	2025-11-21 10:11:35.919055	2025-11-21 10:11:35.910429	2025-11-21 10:11:35.910429
7	3	21	21	video	ringing	rayscan-conv3	0	2025-11-21 10:13:54.678324	\N	2025-11-21 10:13:54.678324	2025-11-21 10:13:54.678324
8	3	21	22	audio	missed	rayscan-conv3	0	2025-11-21 10:15:25.441213	2025-11-21 10:15:25.444289	2025-11-21 10:15:25.441213	2025-11-21 10:15:25.441213
9	3	21	22	video	missed	rayscan-conv3	0	2025-11-21 10:15:29.860384	2025-11-21 10:15:29.86957	2025-11-21 10:15:29.860384	2025-11-21 10:15:29.860384
10	3	21	22	audio	ringing	rayscan-conv3	0	2025-11-21 10:55:48.794955	\N	2025-11-21 10:55:48.794955	2025-11-21 10:55:48.794955
11	3	21	22	video	ringing	rayscan-conv3	0	2025-11-21 10:56:22.340018	\N	2025-11-21 10:56:22.340018	2025-11-21 10:56:22.340018
12	3	21	22	video	ringing	rayscan-conv3	0	2025-11-21 10:56:41.662364	\N	2025-11-21 10:56:41.662364	2025-11-21 10:56:41.662364
13	3	22	21	video	ringing	rayscan-conv3	0	2025-11-21 10:57:45.173755	\N	2025-11-21 10:57:45.173755	2025-11-21 10:57:45.173755
14	3	21	22	audio	rejected	rayscan-conv3	0	2025-11-21 11:11:08.549784	2025-11-21 11:11:39.114045	2025-11-21 11:11:08.549784	2025-11-21 11:11:39.106157
15	3	21	22	video	rejected	rayscan-conv3	0	2025-11-21 11:11:46.34125	2025-11-21 11:13:32.24817	2025-11-21 11:11:46.34125	2025-11-21 11:13:32.240654
17	3	22	21	audio	ringing	rayscan-conv3	0	2025-11-21 11:20:15.466408	\N	2025-11-21 11:20:15.466408	2025-11-21 11:20:15.466408
16	3	22	21	video	answered	rayscan-conv3	0	2025-11-21 11:19:35.029665	\N	2025-11-21 11:19:35.029665	2025-11-21 11:20:18.669759
18	3	22	21	audio	ringing	rayscan-conv3	0	2025-11-21 11:20:24.049941	\N	2025-11-21 11:20:24.049941	2025-11-21 11:20:24.049941
20	3	21	22	video	missed	rayscan-conv3	0	2025-11-21 11:21:04.890919	2025-11-21 11:21:04.905761	2025-11-21 11:21:04.890919	2025-11-21 11:21:04.890919
22	3	21	22	video	rejected	rayscan-conv3	0	2025-11-21 11:21:45.996579	2025-11-21 11:42:13.401747	2025-11-21 11:21:45.996579	2025-11-21 11:42:13.384434
21	3	21	22	audio	rejected	rayscan-conv3	0	2025-11-21 11:21:28.57231	2025-11-21 11:42:14.318886	2025-11-21 11:21:28.57231	2025-11-21 11:42:14.317652
19	3	21	22	audio	rejected	rayscan-conv3	0	2025-11-21 11:20:50.983446	2025-11-21 11:42:15.239104	2025-11-21 11:20:50.983446	2025-11-21 11:42:15.22929
23	3	21	22	video	missed	rayscan-conv3	0	2025-11-27 20:54:57.294314	2025-11-27 20:54:57.37474	2025-11-27 20:54:57.294314	2025-11-27 20:54:57.294314
24	3	21	22	video	missed	rayscan-conv3	0	2025-11-27 21:34:47.169087	2025-11-27 21:34:47.187948	2025-11-27 21:34:47.169087	2025-11-27 21:34:47.169087
\.


--
-- TOC entry 5167 (class 0 OID 16644)
-- Dependencies: 240
-- Data for Name: consultations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.consultations (id, appointment_id, patient_id, doctor_id, consultation_notes, prescription, follow_up_required, follow_up_date, consultation_rating, started_at, ended_at) FROM stdin;
\.


--
-- TOC entry 5175 (class 0 OID 16751)
-- Dependencies: 248
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conversations (id, user_id, doctor_id, type, status, created_at, updated_at, doctor_user_id) FROM stdin;
1	20	9	consultation	active	2025-10-16 09:47:29.316732	2025-10-16 10:24:43.25155	19
2	21	2	consultation	active	2025-11-03 16:16:14.01536	2025-11-06 23:58:34.552891	6
3	21	10	consultation	active	2025-11-06 16:49:21.227802	2025-11-27 21:35:10.875472	22
\.


--
-- TOC entry 5161 (class 0 OID 16566)
-- Dependencies: 234
-- Data for Name: doctor_availability; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctor_availability (id, doctor_id, day_of_week, start_time, end_time, is_active) FROM stdin;
4	2	Monday	09:00:00	12:00:00	t
5	2	Monday	14:00:00	17:00:00	t
6	2	Tuesday	09:00:00	12:00:00	t
7	2	Tuesday	14:00:00	17:00:00	t
8	2	Wednesday	09:00:00	12:00:00	t
9	2	Wednesday	14:00:00	17:00:00	t
10	2	Thursday	09:00:00	12:00:00	t
11	2	Thursday	14:00:00	17:00:00	t
12	2	Friday	09:00:00	12:00:00	t
13	2	Friday	14:00:00	17:00:00	t
14	3	Monday	08:00:00	13:00:00	t
15	3	Tuesday	08:00:00	13:00:00	t
16	3	Wednesday	08:00:00	13:00:00	t
17	3	Thursday	08:00:00	13:00:00	t
18	3	Friday	08:00:00	13:00:00	t
19	3	Saturday	09:00:00	12:00:00	t
20	4	Monday	13:00:00	18:00:00	t
21	4	Tuesday	13:00:00	18:00:00	t
22	4	Wednesday	13:00:00	18:00:00	t
23	4	Thursday	13:00:00	18:00:00	t
24	4	Friday	13:00:00	18:00:00	t
25	4	Saturday	13:00:00	16:00:00	t
26	5	Monday	09:00:00	12:00:00	t
27	5	Monday	14:00:00	17:00:00	t
28	5	Tuesday	09:00:00	12:00:00	t
29	5	Tuesday	14:00:00	17:00:00	t
30	5	Wednesday	09:00:00	12:00:00	t
31	5	Wednesday	14:00:00	17:00:00	t
32	5	Thursday	09:00:00	12:00:00	t
33	5	Thursday	14:00:00	17:00:00	t
34	5	Friday	09:00:00	12:00:00	t
35	5	Friday	14:00:00	17:00:00	t
36	6	Monday	08:00:00	13:00:00	t
37	6	Tuesday	08:00:00	13:00:00	t
38	6	Wednesday	08:00:00	13:00:00	t
39	6	Thursday	08:00:00	13:00:00	t
40	6	Friday	08:00:00	13:00:00	t
41	6	Saturday	09:00:00	12:00:00	t
42	9	Monday	11:00:00	14:00:00	t
43	9	Tuesday	00:00:00	15:00:00	t
44	9	Monday	09:00:00	10:00:00	t
45	9	Wednesday	11:50:00	14:00:00	t
46	10	Monday	00:00:00	14:10:00	t
47	10	Thursday	17:00:00	18:30:00	t
\.


--
-- TOC entry 5151 (class 0 OID 16440)
-- Dependencies: 224
-- Data for Name: doctors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctors (id, user_id, pmdc_number, specialization, qualification, experience_years, consultation_fee, clinic_address, clinic_phone, bio, rating, total_reviews, is_pmdc_verified, availability_status, full_name, profile_image_url) FROM stdin;
2	6	PMDC-001-2024	Cardiologist	MD, FACC - Harvard Medical School	15	120.00	123 Heart Center, Medical District	+1-555-0201	Dr. Marcus Horizon is a board-certified cardiologist with over 15 years of experience in treating heart diseases.	4.80	245	t	available	Dr. Marcus Horizon	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH
3	7	PMDC-002-2024	Psychologist	PhD Psychology - Stanford University	12	90.00	456 Mind Care Center, Downtown	+1-555-0202	Dr. Maria Elena Rodriguez is a clinical psychologist specializing in cognitive behavioral therapy.	4.70	189	t	available	Dr. Maria Elena Rodriguez	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME
4	8	PMDC-003-2024	Orthopedist	MD Orthopedics - Johns Hopkins	10	110.00	789 Bone & Joint Clinic, Uptown	+1-555-0203	Dr. Steff Williams is an orthopedic surgeon specializing in sports medicine and joint replacement.	4.60	156	t	available	Dr. Steff Jessica Williams	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW
5	9	PMDC-004-2024	Urologist	MD Urology - UCLA Medical Center	15	130.00	321 Kidney Care Specialists, Medical Plaza	+1-555-0204	Dr. Sarah Chen is a renowned urologist with expertise in kidney stone treatment and minimally invasive procedures.	4.90	298	t	available	Dr. Sarah Lee Chen	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC
6	10	PMDC-005-2024	Neurologist	MD Neurology - Cleveland Clinic	13	140.00	654 Neuro Center, Hospital District	+1-555-0205	Dr. Michael Brown is a neurologist specializing in epilepsy, stroke treatment, and movement disorders.	4.70	176	t	busy	Dr. Michael Brown	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB
8	17	123456	Surgeon	Mbbs	0	0.00	\N	\N	\N	0.00	0	f	offline	Mus	\N
9	19	1234567	Orthopedist	\N	0	0.00	\N	\N	\N	0.00	0	f	offline	Mushi	\N
10	22	333442215	Orthopedist	2q33	0	0.00	\N	\N	\N	0.00	0	f	offline	haris	\N
\.


--
-- TOC entry 5177 (class 0 OID 16774)
-- Dependencies: 250
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, conversation_id, sender_id, sender_type, message_type, content, file_url, is_read, created_at) FROM stdin;
1	1	20	user	text	hi broo	\N	f	2025-10-16 09:47:35.111996
2	1	20	user	text	hiii	\N	f	2025-10-16 10:24:43.241561
14	2	21	user	text	bro	\N	f	2025-11-06 23:58:34.548726
19	3	22	doctor	text	hi my bro	\N	t	2025-11-21 02:14:46.940807
21	3	22	doctor	text	cutie	\N	t	2025-11-21 10:13:52.672337
3	3	21	user	text	how are you	\N	t	2025-11-06 16:49:31.871388
4	3	21	user	text	nig	\N	t	2025-11-06 16:56:30.517363
5	3	21	user	text	bro	\N	t	2025-11-06 17:28:56.775123
6	3	21	user	text	yo	\N	t	2025-11-06 19:04:03.159306
7	3	21	user	text	bro very pain my nig	\N	t	2025-11-06 19:44:50.360846
8	3	21	user	text	hi broo	\N	t	2025-11-06 22:07:40.348376
9	3	21	user	text	hi mere bhai	\N	t	2025-11-06 22:42:50.422895
10	3	21	user	text	chat bro	\N	t	2025-11-06 23:10:31.351829
11	3	21	user	text	hi	\N	t	2025-11-06 23:29:19.373115
12	3	21	user	text	sir kese ha	\N	t	2025-11-06 23:58:13.843577
13	3	21	user	text	sirrr	\N	t	2025-11-06 23:58:21.68904
15	3	21	user	text	hi nig	\N	t	2025-11-07 00:37:27.989546
16	3	21	user	text	hi bro	\N	t	2025-11-07 13:43:17.864605
17	3	21	user	text	hiii	\N	t	2025-11-07 13:56:41.582146
18	3	21	user	text	hi  doctor	\N	t	2025-11-21 02:04:42.085628
20	3	21	user	text	bro	\N	t	2025-11-21 10:11:23.429652
22	3	21	user	text	bro	\N	t	2025-11-27 21:35:10.862981
\.


--
-- TOC entry 5169 (class 0 OID 16675)
-- Dependencies: 242
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, title, message, notification_type, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 5183 (class 0 OID 16834)
-- Dependencies: 256
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (id, user_id, token, contact_info, contact_type, expires_at, is_used, created_at) FROM stdin;
\.


--
-- TOC entry 5149 (class 0 OID 16422)
-- Dependencies: 222
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (id, user_id, emergency_contact, blood_group, medical_history, allergies, current_medications, insurance_provider, insurance_number) FROM stdin;
1	2	+923007654321	A+	\N	\N	\N	\N	\N
2	12	\N	\N	\N	\N	\N	\N	\N
3	5	\N	\N	\N	\N	\N	\N	\N
4	13	\N	\N	\N	\N	\N	\N	\N
6	18	\N	\N	\N	\N	\N	\N	\N
7	20	\N	\N	\N	\N	\N	\N	\N
8	21	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 5165 (class 0 OID 16616)
-- Dependencies: 238
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, patient_id, appointment_id, amount, payment_method, transaction_id, payment_status, payment_date, refund_amount, refund_date) FROM stdin;
\.


--
-- TOC entry 5153 (class 0 OID 16469)
-- Dependencies: 226
-- Data for Name: pharmacies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pharmacies (id, user_id, pharmacy_name, license_number, owner_name, pharmacy_address, pharmacy_phone, operating_hours, delivery_available, latitude, longitude) FROM stdin;
1	1	Healthy Life Pharmacy	PH001	Dr. Ahmed Khan	Main Street, Lahore	+92-42-111-2222	8:00 AM - 10:00 PM	t	31.54970000	74.34360000
2	2	City Medico	PH002	Dr. Sarah Ali	Mall Road, Lahore	+92-42-333-4444	9:00 AM - 11:00 PM	t	31.52040000	74.35870000
3	3	Good Health Drugs	PH003	Dr. Hassan Shah	Iqbal Town, Lahore	+92-42-555-6666	7:00 AM - 9:00 PM	f	31.59250000	74.30950000
\.


--
-- TOC entry 5181 (class 0 OID 16819)
-- Dependencies: 254
-- Data for Name: pharmacy_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pharmacy_products (id, pharmacy_id, name, category, price, in_stock, created_at) FROM stdin;
1	1	Throat Lozenges	covid19	47.40	f	2025-09-28 12:02:43.396112
2	1	Zinc Supplements	covid19	134.87	t	2025-09-28 12:02:43.398275
3	1	Metformin 500mg	pancreatics	96.13	t	2025-09-28 12:02:43.399813
4	1	Sertraline 50mg	nuero_pill	212.50	t	2025-09-28 12:02:43.400917
5	1	Vitamin C 1000mg	covid19	75.25	t	2025-09-28 12:02:43.402368
6	1	Probiotics	immune_system	252.00	t	2025-09-28 12:02:43.403494
7	1	Diclofenac Gel	pain_killers	86.15	t	2025-09-28 12:02:43.405051
8	1	Echinacea Extract	immune_system	221.69	t	2025-09-28 12:02:43.405938
9	1	Pancreatin Enzymes	pancreatics	382.39	t	2025-09-28 12:02:43.406772
10	1	Eye Drops	other	71.48	t	2025-09-28 12:02:43.407442
11	1	Lisinopril 10mg	blood_pressure	172.59	t	2025-09-28 12:02:43.408094
12	1	Cetrizine 10mg	other	61.09	t	2025-09-28 12:02:43.408691
13	1	Insulin Glargine	pancreatics	891.29	t	2025-09-28 12:02:43.409267
14	1	Multivitamin Complex	immune_system	139.76	t	2025-09-28 12:02:43.409876
15	1	Carbamazepine 200mg	epiapcy	217.10	t	2025-09-28 12:02:43.410528
16	1	Antacid Tablets	stomach	34.88	t	2025-09-28 12:02:43.411106
17	1	Tramadol 50mg	pain_killers	145.08	t	2025-09-28 12:02:43.411765
18	1	Omeprazole 20mg	stomach	127.73	t	2025-09-28 12:02:43.4124
19	1	Lorazepam 1mg	nuero_pill	149.00	t	2025-09-28 12:02:43.41314
20	1	Aspirin 300mg	pain_killers	23.00	t	2025-09-28 12:02:43.41401
21	1	Hydrochlorothiazide	blood_pressure	95.13	t	2025-09-28 12:02:43.414855
22	1	Valproic Acid 500mg	epiapcy	298.98	t	2025-09-28 12:02:43.415845
23	1	Loperamide 2mg	stomach	66.72	t	2025-09-28 12:02:43.41666
24	1	Hand Sanitizer	other	37.28	t	2025-09-28 12:02:43.41741
25	2	Valproic Acid 500mg	epiapcy	271.22	t	2025-09-28 12:02:43.41834
26	2	Hydrochlorothiazide	blood_pressure	87.86	t	2025-09-28 12:02:43.419103
27	2	Zinc Supplements	covid19	115.43	t	2025-09-28 12:02:43.419891
28	2	Metoprolol 25mg	blood_pressure	221.33	t	2025-09-28 12:02:43.420637
29	2	Paracetamol 500mg	covid19	21.45	t	2025-09-28 12:02:43.421323
30	2	Lisinopril 10mg	blood_pressure	160.24	t	2025-09-28 12:02:43.422036
31	2	Antacid Tablets	stomach	34.49	t	2025-09-28 12:02:43.422872
32	2	Domperidone 10mg	stomach	96.57	t	2025-09-28 12:02:43.42362
33	2	Hand Sanitizer	other	49.81	t	2025-09-28 12:02:43.424402
34	2	Probiotics	immune_system	240.85	t	2025-09-28 12:02:43.425184
35	2	Echinacea Extract	immune_system	160.16	t	2025-09-28 12:02:43.426064
36	2	Aspirin 300mg	pain_killers	27.96	t	2025-09-28 12:02:43.426877
37	2	Cetrizine 10mg	other	60.95	t	2025-09-28 12:02:43.427667
38	2	Tramadol 50mg	pain_killers	100.92	f	2025-09-28 12:02:43.428348
39	2	Diclofenac Gel	pain_killers	73.11	f	2025-09-28 12:02:43.429204
40	2	Omeprazole 20mg	stomach	118.58	t	2025-09-28 12:02:43.429965
41	2	Insulin Glargine	pancreatics	743.16	t	2025-09-28 12:02:43.430704
42	2	Carbamazepine 200mg	epiapcy	195.90	t	2025-09-28 12:02:43.431381
43	2	Amlodipine 5mg	blood_pressure	159.76	t	2025-09-28 12:02:43.432209
44	3	Sertraline 50mg	nuero_pill	211.86	t	2025-09-28 12:02:43.433148
45	3	Vitamin D3 2000IU	immune_system	107.08	t	2025-09-28 12:02:43.433924
46	3	Phenytoin 100mg	epiapcy	173.98	t	2025-09-28 12:02:43.434642
47	3	Loperamide 2mg	stomach	68.15	t	2025-09-28 12:02:43.435336
48	3	Eye Drops	other	94.48	t	2025-09-28 12:02:43.436046
49	3	Pancreatin Enzymes	pancreatics	290.19	t	2025-09-28 12:02:43.436725
50	3	Diclofenac Gel	pain_killers	88.53	t	2025-09-28 12:02:43.437529
51	3	Echinacea Extract	immune_system	206.26	t	2025-09-28 12:02:43.438325
52	3	Antacid Tablets	stomach	43.52	t	2025-09-28 12:02:43.439104
53	3	Insulin Glargine	pancreatics	960.28	t	2025-09-28 12:02:43.439804
54	3	Metoprolol 25mg	blood_pressure	246.23	t	2025-09-28 12:02:43.440486
55	3	Zinc Supplements	covid19	103.58	t	2025-09-28 12:02:43.44114
56	3	Vitamin C 1000mg	covid19	88.66	f	2025-09-28 12:02:43.441781
57	3	Multivitamin Complex	immune_system	117.15	t	2025-09-28 12:02:43.4425
58	3	Carbamazepine 200mg	epiapcy	162.68	t	2025-09-28 12:02:43.443227
\.


--
-- TOC entry 5159 (class 0 OID 16532)
-- Dependencies: 232
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, scan_id, patient_id, doctor_id, report_type, diagnosis, recommendations, severity_level, report_pdf_path, is_verified, verified_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5171 (class 0 OID 16694)
-- Dependencies: 244
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reviews (id, patient_id, doctor_id, appointment_id, rating, review_text, created_at) FROM stdin;
\.


--
-- TOC entry 5155 (class 0 OID 16490)
-- Dependencies: 228
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scans (id, patient_id, scan_type, image_path, original_filename, file_size, upload_date, scan_status, ai_confidence_score, processing_time_seconds) FROM stdin;
\.


--
-- TOC entry 5179 (class 0 OID 16793)
-- Dependencies: 252
-- Data for Name: ultrasound_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ultrasound_reports (id, user_id, scan_type, image_url, ai_analysis, result, confidence_score, recommended_doctor_id, status, created_at, updated_at) FROM stdin;
1	21	kidney	/uploads/ultrasound/ultrasound-1762172665696-354385783.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 17:24:26.986949	2025-11-03 17:24:26.986949
2	21	kidney	/uploads/ultrasound/ultrasound-1762172842619-262972057.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 17:27:22.96084	2025-11-03 17:27:22.96084
3	21	kidney	/uploads/ultrasound/ultrasound-1762172979550-508270827.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 17:29:40.33145	2025-11-03 17:29:40.33145
4	21	kidney	/uploads/ultrasound/ultrasound-1762174889651-805995993.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 18:01:30.489357	2025-11-03 18:01:30.489357
5	21	kidney	/uploads/ultrasound/ultrasound-1762175257404-520135689.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 18:07:38.209385	2025-11-03 18:07:38.209385
6	21	kidney	/uploads/ultrasound/ultrasound-1762175291831-972951734.jpg	Normal Kidney. Confidence: 100%	not_detected	1.00	\N	completed	2025-11-03 18:08:12.143865	2025-11-03 18:08:12.143865
38	21	kidney	/uploads/ultrasound/ultrasound-1762429420105-233980909.jpg	Stone Detected. Confidence: 100%	detected	1.00	\N	completed	2025-11-06 16:43:41.383273	2025-11-06 16:43:41.383273
39	21	kidney	/uploads/ultrasound/ultrasound-1762429441834-400628912.jpg	Stone Detected. Confidence: 99.99%	detected	1.00	\N	completed	2025-11-06 16:44:02.111632	2025-11-06 16:44:02.111632
40	21	kidney	/uploads/ultrasound/ultrasound-1762429472825-719815123.jpg	Stone Detected. Confidence: 99.99%	detected	1.00	\N	completed	2025-11-06 16:44:33.184269	2025-11-06 16:44:33.184269
41	21	kidney	/uploads/ultrasound/ultrasound-1762453698104-991056214.jpg	Stone Detected. Confidence: 99.99%	detected	1.00	\N	completed	2025-11-06 23:28:19.43512	2025-11-06 23:28:19.43512
42	21	kidney	/uploads/ultrasound/ultrasound-1762453710308-889757132.jpg	Stone Detected. Confidence: 100%	detected	1.00	\N	completed	2025-11-06 23:28:30.593696	2025-11-06 23:28:30.593696
43	21	kidney	/uploads/ultrasound/ultrasound-1763709053808-421048972.jpg	Stone Detected. Confidence: 99.98%	detected	1.00	\N	completed	2025-11-21 12:10:55.119551	2025-11-21 12:10:55.119551
44	21	kidney	/uploads/ultrasound/ultrasound-1763709066820-668514091.jpg	Stone Detected. Confidence: 94.9%	detected	0.95	\N	completed	2025-11-21 12:11:07.069689	2025-11-21 12:11:07.069689
\.


--
-- TOC entry 5185 (class 0 OID 16849)
-- Dependencies: 258
-- Data for Name: user_health_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_health_metrics (id, user_id, heart_rate, calories_burned, weight, height, blood_pressure_systolic, blood_pressure_diastolic, recorded_at) FROM stdin;
\.


--
-- TOC entry 5147 (class 0 OID 16401)
-- Dependencies: 220
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, phone, full_name, date_of_birth, gender, address, city, country, role, profile_image, is_active, is_verified, created_at, updated_at) FROM stdin;
1	admin@rayscan.com	$2b$12$hash_placeholder	\N	System Admin	\N	\N	\N	\N	Pakistan	admin	\N	t	t	2025-08-04 21:18:58.611279	2025-08-04 21:18:58.611279
2	patient@test.com	$2b$12$hash_placeholder	+923001234567	John Doe	\N	\N	\N	Lahore	Pakistan	patient	\N	t	f	2025-08-04 21:18:58.611279	2025-08-04 21:18:58.611279
3	doctor@test.com	$2b$12$hash_placeholder	+923009876543	Dr. Sarah Ahmed	\N	\N	\N	Karachi	Pakistan	doctor	\N	t	f	2025-08-04 21:18:58.611279	2025-08-04 21:18:58.611279
4	test@test.com	$2a$10$leV/dxX05qVmY/J8cre9Y.OWzsCiI9mss/pzv3wbIHSFh5HBZSK1u	\N	Test User	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-27 12:22:11.953105	2025-09-27 12:22:11.953105
5	ali@gmail.com	$2a$10$1oPGIdfSOO8Sj6YPuM6gDOqfCtSYho9C4khkJMHRuvqkqcE5eWbze	\N	ali	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-27 12:37:08.747806	2025-09-27 12:37:08.747806
6	marcus.horizon@rayscan.com	$2a$10$rayscandefaultpass123456789012345678901234567890123456	+1-555-0101	Dr. Marcus Horizon	\N	\N	\N	\N	Pakistan	doctor	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MH	t	t	2025-09-27 13:30:55.456385	2025-09-27 13:30:55.456385
7	maria.elena@rayscan.com	$2a$10$rayscandefaultpass123456789012345678901234567890123456	+1-555-0102	Dr. Maria Elena Rodriguez	\N	\N	\N	\N	Pakistan	doctor	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=ME	t	t	2025-09-27 13:30:55.515122	2025-09-27 13:30:55.515122
8	steff.williams@rayscan.com	$2a$10$rayscandefaultpass123456789012345678901234567890123456	+1-555-0103	Dr. Steff Jessica Williams	\N	\N	\N	\N	Pakistan	doctor	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SW	t	t	2025-09-27 13:30:55.5163	2025-09-27 13:30:55.5163
9	sarah.chen@rayscan.com	$2a$10$rayscandefaultpass123456789012345678901234567890123456	+1-555-0104	Dr. Sarah Lee Chen	\N	\N	\N	\N	Pakistan	doctor	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=SC	t	t	2025-09-27 13:30:55.517218	2025-09-27 13:30:55.517218
10	michael.brown@rayscan.com	$2a$10$rayscandefaultpass123456789012345678901234567890123456	+1-555-0105	Dr. Michael Brown	\N	\N	\N	\N	Pakistan	doctor	https://via.placeholder.com/200x200/0E807F/FFFFFF?text=MB	t	t	2025-09-27 13:30:55.518482	2025-09-27 13:30:55.518482
11	testuser@rayscan.com	$2a$10$yaogfpMbHjrQIjp9YIRTPOwR/f1HB0rO3978Ww75f0Of9Wb7.Kp/2	\N	Test User	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-27 13:36:11.152446	2025-09-27 13:36:11.152446
12	test@example.com	$2a$10$c7u2h4OQQXgBEOXBMZKWue3iG9AI7758z5eeJzsLSJkONiDOqp94O	\N	Test User	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-28 12:03:52.602225	2025-09-28 12:03:52.602225
13	test2@test.com	$2a$10$USFpwaoiKfaymtQo2XeI7OujF2l23lUeWnX5vT2j7XnH0/olYlm9q	1234567891	Test User 2	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-28 13:56:00.520013	2025-09-28 13:56:00.520013
16	hariscutie@gmail.com	$2a$10$WbyoqRXoOwYMZoT4EvP98uY9V4k92uXXWIfAexUlGfnt/5kCLi2.O	\N	Haris	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-30 14:30:56.566878	2025-09-30 14:30:56.566878
17	mushi123@gmail.com	$2a$10$RBAdtlTxkdeekBovuddPhO2nTUUQqmI0h6AG5Uk6son43.Cl88unW	03345010416	Mus	\N	Male	\N	\N	Pakistan	doctor	\N	t	f	2025-09-30 14:34:19.253793	2025-09-30 14:34:19.253793
18	itrat@gmail.com	$2a$10$7aJArzXdYzDCuO.hd2Y1x.C/yaKFuKkKR3hNDRsCpAXuQ2lxdT6h6	\N	itrat	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-09-30 14:50:51.827162	2025-09-30 14:50:51.827162
19	mushi002@gmail.com	$2a$10$9ONWjQpvBpsP6v/GmvowaeAytR5Mop.6pp/DADWdpA5E0ts.WOM4a	3345010416	Mushi	\N	Male	\N	\N	Pakistan	doctor	\N	t	f	2025-10-16 00:45:01.730104	2025-10-16 00:45:01.730104
20	coolguy123@gmail.com	$2a$10$oaJTdbnCuB5ibYJ2wBHsk.jLYkCvwo7UT1ly3f6H2U6bj7AM5ti/q	\N	coolguy	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-10-16 00:49:29.277913	2025-10-16 00:49:29.277913
21	mu@gmail.com	$2a$10$WfutrDEnguKfmXfR9RlsOOHXX3r7DzRm6SWyY3R7xDpFns.WKr7eq	\N	Mushi	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-11-03 16:14:59.586406	2025-11-03 16:14:59.586406
22	harisa@gmail.com	$2a$10$Omi9.5OexSw6h7bAKnwlPO6Z9h2xXR7i4hSa1gWc06/xP6fKCy78.	qs2	haris	\N	Male	\N	\N	Pakistan	doctor	\N	t	f	2025-11-03 16:19:58.3299	2025-11-03 16:19:58.3299
23	bro@gmail.com	$2a$10$nY5YQkoKUwiebz2ByUmnD.YhOPiLdP5Pu/7aUSI5yOiSV4Hy0onsq	\N	Bro	\N	\N	\N	\N	Pakistan	patient	\N	t	f	2025-11-27 21:09:23.455406	2025-11-27 21:09:23.455406
\.


--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 245
-- Name: admin_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_logs_id_seq', 1, false);


--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 229
-- Name: ai_diagnoses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ai_diagnoses_id_seq', 1, false);


--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 235
-- Name: appointments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_id_seq', 33, true);


--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 259
-- Name: call_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.call_logs_id_seq', 24, true);


--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 239
-- Name: consultations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.consultations_id_seq', 1, false);


--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 247
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conversations_id_seq', 3, true);


--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 233
-- Name: doctor_availability_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctor_availability_id_seq', 47, true);


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 223
-- Name: doctors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctors_id_seq', 10, true);


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 249
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 22, true);


--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 241
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 255
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 1, false);


--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 221
-- Name: patients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patients_id_seq', 8, true);


--
-- TOC entry 5227 (class 0 OID 0)
-- Dependencies: 237
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_id_seq', 1, false);


--
-- TOC entry 5228 (class 0 OID 0)
-- Dependencies: 225
-- Name: pharmacies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pharmacies_id_seq', 3, true);


--
-- TOC entry 5229 (class 0 OID 0)
-- Dependencies: 253
-- Name: pharmacy_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pharmacy_products_id_seq', 58, true);


--
-- TOC entry 5230 (class 0 OID 0)
-- Dependencies: 231
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 1, false);


--
-- TOC entry 5231 (class 0 OID 0)
-- Dependencies: 243
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reviews_id_seq', 1, false);


--
-- TOC entry 5232 (class 0 OID 0)
-- Dependencies: 227
-- Name: scans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scans_id_seq', 1, false);


--
-- TOC entry 5233 (class 0 OID 0)
-- Dependencies: 251
-- Name: ultrasound_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ultrasound_reports_id_seq', 44, true);


--
-- TOC entry 5234 (class 0 OID 0)
-- Dependencies: 257
-- Name: user_health_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_health_metrics_id_seq', 1, false);


--
-- TOC entry 5235 (class 0 OID 0)
-- Dependencies: 219
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 23, true);


--
-- TOC entry 4943 (class 2606 OID 16732)
-- Name: admin_logs admin_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_logs
    ADD CONSTRAINT admin_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4892 (class 2606 OID 16521)
-- Name: ai_diagnoses ai_diagnoses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_diagnoses
    ADD CONSTRAINT ai_diagnoses_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 16523)
-- Name: ai_diagnoses ai_diagnoses_scan_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_diagnoses
    ADD CONSTRAINT ai_diagnoses_scan_id_key UNIQUE (scan_id);


--
-- TOC entry 4909 (class 2606 OID 16600)
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- TOC entry 4960 (class 2606 OID 25083)
-- Name: call_logs call_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_logs
    ADD CONSTRAINT call_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4925 (class 2606 OID 16655)
-- Name: consultations consultations_appointment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations
    ADD CONSTRAINT consultations_appointment_id_key UNIQUE (appointment_id);


--
-- TOC entry 4927 (class 2606 OID 16653)
-- Name: consultations consultations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations
    ADD CONSTRAINT consultations_pkey PRIMARY KEY (id);


--
-- TOC entry 4948 (class 2606 OID 16762)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 4904 (class 2606 OID 16575)
-- Name: doctor_availability doctor_availability_doctor_id_day_of_week_start_time_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability
    ADD CONSTRAINT doctor_availability_doctor_id_day_of_week_start_time_key UNIQUE (doctor_id, day_of_week, start_time);


--
-- TOC entry 4906 (class 2606 OID 16573)
-- Name: doctor_availability doctor_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability
    ADD CONSTRAINT doctor_availability_pkey PRIMARY KEY (id);


--
-- TOC entry 4868 (class 2606 OID 16454)
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (id);


--
-- TOC entry 4870 (class 2606 OID 16458)
-- Name: doctors doctors_pmdc_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pmdc_number_key UNIQUE (pmdc_number);


--
-- TOC entry 4872 (class 2606 OID 16456)
-- Name: doctors doctors_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_user_id_key UNIQUE (user_id);


--
-- TOC entry 4950 (class 2606 OID 16786)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 4935 (class 2606 OID 16684)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4956 (class 2606 OID 16842)
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4864 (class 2606 OID 16430)
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- TOC entry 4866 (class 2606 OID 16432)
-- Name: patients patients_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_user_id_key UNIQUE (user_id);


--
-- TOC entry 4919 (class 2606 OID 16626)
-- Name: payments payments_appointment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_appointment_id_key UNIQUE (appointment_id);


--
-- TOC entry 4921 (class 2606 OID 16624)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- TOC entry 4923 (class 2606 OID 16628)
-- Name: payments payments_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_transaction_id_key UNIQUE (transaction_id);


--
-- TOC entry 4880 (class 2606 OID 16481)
-- Name: pharmacies pharmacies_license_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacies
    ADD CONSTRAINT pharmacies_license_number_key UNIQUE (license_number);


--
-- TOC entry 4882 (class 2606 OID 16477)
-- Name: pharmacies pharmacies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacies
    ADD CONSTRAINT pharmacies_pkey PRIMARY KEY (id);


--
-- TOC entry 4884 (class 2606 OID 16479)
-- Name: pharmacies pharmacies_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacies
    ADD CONSTRAINT pharmacies_user_id_key UNIQUE (user_id);


--
-- TOC entry 4954 (class 2606 OID 16827)
-- Name: pharmacy_products pharmacy_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacy_products
    ADD CONSTRAINT pharmacy_products_pkey PRIMARY KEY (id);


--
-- TOC entry 4902 (class 2606 OID 16545)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 4941 (class 2606 OID 16703)
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 4890 (class 2606 OID 16501)
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- TOC entry 4952 (class 2606 OID 16806)
-- Name: ultrasound_reports ultrasound_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ultrasound_reports
    ADD CONSTRAINT ultrasound_reports_pkey PRIMARY KEY (id);


--
-- TOC entry 4958 (class 2606 OID 16855)
-- Name: user_health_metrics user_health_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_health_metrics
    ADD CONSTRAINT user_health_metrics_pkey PRIMARY KEY (id);


--
-- TOC entry 4859 (class 2606 OID 16417)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4861 (class 2606 OID 16415)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4944 (class 1259 OID 16739)
-- Name: idx_admin_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_logs_action ON public.admin_logs USING btree (action);


--
-- TOC entry 4945 (class 1259 OID 16738)
-- Name: idx_admin_logs_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_logs_admin ON public.admin_logs USING btree (admin_id);


--
-- TOC entry 4946 (class 1259 OID 16740)
-- Name: idx_admin_logs_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_logs_created ON public.admin_logs USING btree (created_at);


--
-- TOC entry 4895 (class 1259 OID 16530)
-- Name: idx_ai_diagnoses_result; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_diagnoses_result ON public.ai_diagnoses USING btree (diagnosis_result);


--
-- TOC entry 4896 (class 1259 OID 16529)
-- Name: idx_ai_diagnoses_scan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_diagnoses_scan ON public.ai_diagnoses USING btree (scan_id);


--
-- TOC entry 4910 (class 1259 OID 16613)
-- Name: idx_appointments_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_date ON public.appointments USING btree (appointment_date);


--
-- TOC entry 4911 (class 1259 OID 16612)
-- Name: idx_appointments_doctor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_doctor ON public.appointments USING btree (doctor_id);


--
-- TOC entry 4912 (class 1259 OID 16611)
-- Name: idx_appointments_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_patient ON public.appointments USING btree (patient_id);


--
-- TOC entry 4913 (class 1259 OID 16614)
-- Name: idx_appointments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_status ON public.appointments USING btree (status);


--
-- TOC entry 4961 (class 1259 OID 25099)
-- Name: idx_call_logs_caller; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_call_logs_caller ON public.call_logs USING btree (caller_user_id);


--
-- TOC entry 4962 (class 1259 OID 25101)
-- Name: idx_call_logs_conversation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_call_logs_conversation ON public.call_logs USING btree (conversation_id);


--
-- TOC entry 4963 (class 1259 OID 25100)
-- Name: idx_call_logs_receiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_call_logs_receiver ON public.call_logs USING btree (receiver_user_id);


--
-- TOC entry 4964 (class 1259 OID 25102)
-- Name: idx_call_logs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_call_logs_status ON public.call_logs USING btree (status);


--
-- TOC entry 4928 (class 1259 OID 16671)
-- Name: idx_consultations_appointment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_consultations_appointment ON public.consultations USING btree (appointment_id);


--
-- TOC entry 4929 (class 1259 OID 16673)
-- Name: idx_consultations_doctor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_consultations_doctor ON public.consultations USING btree (doctor_id);


--
-- TOC entry 4930 (class 1259 OID 16672)
-- Name: idx_consultations_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_consultations_patient ON public.consultations USING btree (patient_id);


--
-- TOC entry 4907 (class 1259 OID 16581)
-- Name: idx_doctor_availability_schedule; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctor_availability_schedule ON public.doctor_availability USING btree (doctor_id, day_of_week);


--
-- TOC entry 4873 (class 1259 OID 16465)
-- Name: idx_doctors_pmdc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctors_pmdc ON public.doctors USING btree (pmdc_number);


--
-- TOC entry 4874 (class 1259 OID 16467)
-- Name: idx_doctors_rating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctors_rating ON public.doctors USING btree (rating);


--
-- TOC entry 4875 (class 1259 OID 16466)
-- Name: idx_doctors_specialization; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctors_specialization ON public.doctors USING btree (specialization);


--
-- TOC entry 4876 (class 1259 OID 16464)
-- Name: idx_doctors_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doctors_user ON public.doctors USING btree (user_id);


--
-- TOC entry 4931 (class 1259 OID 16692)
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at);


--
-- TOC entry 4932 (class 1259 OID 16691)
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);


--
-- TOC entry 4933 (class 1259 OID 16690)
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- TOC entry 4862 (class 1259 OID 16438)
-- Name: idx_patients_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patients_user ON public.patients USING btree (user_id);


--
-- TOC entry 4914 (class 1259 OID 16640)
-- Name: idx_payments_appointment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_appointment ON public.payments USING btree (appointment_id);


--
-- TOC entry 4915 (class 1259 OID 16639)
-- Name: idx_payments_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_patient ON public.payments USING btree (patient_id);


--
-- TOC entry 4916 (class 1259 OID 16641)
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_status ON public.payments USING btree (payment_status);


--
-- TOC entry 4917 (class 1259 OID 16642)
-- Name: idx_payments_transaction; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_transaction ON public.payments USING btree (transaction_id);


--
-- TOC entry 4877 (class 1259 OID 16488)
-- Name: idx_pharmacies_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pharmacies_location ON public.pharmacies USING btree (latitude, longitude);


--
-- TOC entry 4878 (class 1259 OID 16487)
-- Name: idx_pharmacies_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pharmacies_user ON public.pharmacies USING btree (user_id);


--
-- TOC entry 4897 (class 1259 OID 16562)
-- Name: idx_reports_doctor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_doctor ON public.reports USING btree (doctor_id);


--
-- TOC entry 4898 (class 1259 OID 16561)
-- Name: idx_reports_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_patient ON public.reports USING btree (patient_id);


--
-- TOC entry 4899 (class 1259 OID 16564)
-- Name: idx_reports_scan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_scan ON public.reports USING btree (scan_id);


--
-- TOC entry 4900 (class 1259 OID 16563)
-- Name: idx_reports_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_type ON public.reports USING btree (report_type);


--
-- TOC entry 4936 (class 1259 OID 16721)
-- Name: idx_reviews_appointment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_appointment ON public.reviews USING btree (appointment_id);


--
-- TOC entry 4937 (class 1259 OID 16720)
-- Name: idx_reviews_doctor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_doctor ON public.reviews USING btree (doctor_id);


--
-- TOC entry 4938 (class 1259 OID 16719)
-- Name: idx_reviews_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_patient ON public.reviews USING btree (patient_id);


--
-- TOC entry 4939 (class 1259 OID 16722)
-- Name: idx_reviews_rating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_rating ON public.reviews USING btree (rating);


--
-- TOC entry 4885 (class 1259 OID 16507)
-- Name: idx_scans_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_patient ON public.scans USING btree (patient_id);


--
-- TOC entry 4886 (class 1259 OID 16509)
-- Name: idx_scans_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_status ON public.scans USING btree (scan_status);


--
-- TOC entry 4887 (class 1259 OID 16508)
-- Name: idx_scans_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_type ON public.scans USING btree (scan_type);


--
-- TOC entry 4888 (class 1259 OID 16510)
-- Name: idx_scans_upload_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_upload_date ON public.scans USING btree (upload_date);


--
-- TOC entry 4855 (class 1259 OID 16420)
-- Name: idx_users_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_active ON public.users USING btree (is_active);


--
-- TOC entry 4856 (class 1259 OID 16418)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 4857 (class 1259 OID 16419)
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- TOC entry 5000 (class 2620 OID 16744)
-- Name: appointments update_appointments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 4999 (class 2620 OID 16743)
-- Name: reports update_reports_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON public.reports FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 4998 (class 2620 OID 16742)
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 4985 (class 2606 OID 16733)
-- Name: admin_logs admin_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_logs
    ADD CONSTRAINT admin_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4969 (class 2606 OID 16524)
-- Name: ai_diagnoses ai_diagnoses_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_diagnoses
    ADD CONSTRAINT ai_diagnoses_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 4974 (class 2606 OID 16606)
-- Name: appointments appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE CASCADE;


--
-- TOC entry 4975 (class 2606 OID 16601)
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4995 (class 2606 OID 25089)
-- Name: call_logs call_logs_caller_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_logs
    ADD CONSTRAINT call_logs_caller_user_id_fkey FOREIGN KEY (caller_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4996 (class 2606 OID 25084)
-- Name: call_logs call_logs_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_logs
    ADD CONSTRAINT call_logs_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 4997 (class 2606 OID 25094)
-- Name: call_logs call_logs_receiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_logs
    ADD CONSTRAINT call_logs_receiver_user_id_fkey FOREIGN KEY (receiver_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4978 (class 2606 OID 16656)
-- Name: consultations consultations_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations
    ADD CONSTRAINT consultations_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE;


--
-- TOC entry 4979 (class 2606 OID 16666)
-- Name: consultations consultations_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations
    ADD CONSTRAINT consultations_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE CASCADE;


--
-- TOC entry 4980 (class 2606 OID 16661)
-- Name: consultations consultations_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consultations
    ADD CONSTRAINT consultations_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4986 (class 2606 OID 16768)
-- Name: conversations conversations_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE CASCADE;


--
-- TOC entry 4987 (class 2606 OID 25066)
-- Name: conversations conversations_doctor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_doctor_user_id_fkey FOREIGN KEY (doctor_user_id) REFERENCES public.users(id);


--
-- TOC entry 4988 (class 2606 OID 16763)
-- Name: conversations conversations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4973 (class 2606 OID 16576)
-- Name: doctor_availability doctor_availability_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_availability
    ADD CONSTRAINT doctor_availability_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE CASCADE;


--
-- TOC entry 4966 (class 2606 OID 16459)
-- Name: doctors doctors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4989 (class 2606 OID 16787)
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 4981 (class 2606 OID 16685)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4993 (class 2606 OID 16843)
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4965 (class 2606 OID 16433)
-- Name: patients patients_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4976 (class 2606 OID 16634)
-- Name: payments payments_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL;


--
-- TOC entry 4977 (class 2606 OID 16629)
-- Name: payments payments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4967 (class 2606 OID 16482)
-- Name: pharmacies pharmacies_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacies
    ADD CONSTRAINT pharmacies_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4992 (class 2606 OID 16828)
-- Name: pharmacy_products pharmacy_products_pharmacy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pharmacy_products
    ADD CONSTRAINT pharmacy_products_pharmacy_id_fkey FOREIGN KEY (pharmacy_id) REFERENCES public.pharmacies(id) ON DELETE CASCADE;


--
-- TOC entry 4970 (class 2606 OID 16556)
-- Name: reports reports_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE SET NULL;


--
-- TOC entry 4971 (class 2606 OID 16551)
-- Name: reports reports_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4972 (class 2606 OID 16546)
-- Name: reports reports_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 4982 (class 2606 OID 16714)
-- Name: reviews reviews_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL;


--
-- TOC entry 4983 (class 2606 OID 16709)
-- Name: reviews reviews_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id) ON DELETE CASCADE;


--
-- TOC entry 4984 (class 2606 OID 16704)
-- Name: reviews reviews_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4968 (class 2606 OID 16502)
-- Name: scans scans_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- TOC entry 4990 (class 2606 OID 16812)
-- Name: ultrasound_reports ultrasound_reports_recommended_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ultrasound_reports
    ADD CONSTRAINT ultrasound_reports_recommended_doctor_id_fkey FOREIGN KEY (recommended_doctor_id) REFERENCES public.doctors(id) ON DELETE SET NULL;


--
-- TOC entry 4991 (class 2606 OID 16807)
-- Name: ultrasound_reports ultrasound_reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ultrasound_reports
    ADD CONSTRAINT ultrasound_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4994 (class 2606 OID 16856)
-- Name: user_health_metrics user_health_metrics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_health_metrics
    ADD CONSTRAINT user_health_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-11-27 22:43:21

--
-- PostgreSQL database dump complete
--

