package models

import (
	"database/sql"
	"encoding/json"
)

type NullString struct {
	sql.NullString
}

func NewNullString(s string) NullString {
	return NullString{sql.NullString{String: s, Valid: true}}
}

func (s NullString) String() string {
	if !s.Valid {
		return ""
	}
	return s.NullString.String
}

func (s NullString) StringRef() *string {
	if !s.NullString.Valid {
		return nil
	}
	return &s.NullString.String
}

func (s NullString) MarshalJSON() ([]byte, error) {
	if !s.Valid {
		return []byte("null"), nil
	}
	return json.Marshal(s.NullString.String)
}

func (s *NullString) UnmarshalJSON(data []byte) error {
	if string(data) == "null" {
		s.Valid = false
		return nil
	}
	s.Valid = true
	return json.Unmarshal(data, &s.NullString.String)
}
