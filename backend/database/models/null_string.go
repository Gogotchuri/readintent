package models

import (
	"database/sql"
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
