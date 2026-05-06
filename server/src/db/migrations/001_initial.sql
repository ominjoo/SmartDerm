CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE skin_type AS ENUM (
  'oily', 'dry', 'combination', 'sensitive', 'normal'
);

CREATE TYPE face_zone AS ENUM (
  'forehead', 'nose', 'chin', 'left_cheek', 
  'right_cheek', 'jawline', 'temples', 'neck'
);

CREATE TYPE breakout_type AS ENUM (
  'comedone_open',    -- blackhead
  'comedone_closed',  -- whitehead
  'papule',           -- small red bump, no pus
  'pustule',          -- red bump with pus
  'nodule',           -- large, deep, solid
  'cyst',             -- large, deep, pus-filled
  'milia'             -- tiny white keratin-filled cysts
);

CREATE TYPE time_of_day AS ENUM ('morning', 'evening', 'both');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE skin_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  skin_type skin_type,
  concerns TEXT[],
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  comedogenic_rating INTEGER CHECK (comedogenic_rating BETWEEN 0 AND 5),
  irritation_rating INTEGER CHECK (irritation_rating BETWEEN 0 AND 5),
  avoid_for TEXT[],
  ingredient_function TEXT
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  brand TEXT,
  product_type TEXT
);

CREATE TABLE product_ingredients (
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  ingredient_id UUID REFERENCES ingredients(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, ingredient_id)
);

CREATE TABLE regimens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,  -- user-defined name
  time_of_day time_of_day,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- which products are in each regimen, and in what order
CREATE TABLE regimen_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regimen_id UUID REFERENCES regimens(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,  -- apply cleanser first, then toner, then moisturizer
  notes TEXT  -- e.g. "only use 2x per week"
);

CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  
  -- breakout details
  severity INTEGER CHECK (severity BETWEEN 1 AND 5),
  breakout_type_face_zones JSONB,  -- {"cyst": ["chin"], "papule": ["forehead", "nose"]}
  
  
  -- regimen used
  -- nullable because they might not have a saved regimen yet
  regimen_id UUID REFERENCES regimens(id) ON DELETE SET NULL,
  
  -- lifestyle factors
  stress_level INTEGER CHECK (stress_level BETWEEN 1 AND 5),
  hours_of_sleep NUMERIC(3,1),   -- e.g. 6.5
  diet_notes TEXT,               -- "ate a lot of dairy this week"
  
  -- free text + media
  notes TEXT,
  photo_url TEXT,
  
  -- filled in after ML service runs
  ml_classification TEXT,
  ml_confidence NUMERIC(4,3),    -- e.g. 0.847 = 84.7% confidence
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);
