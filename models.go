package main

type Ad struct {
	RedirectUrl string `json:"productPath"`
	Text        string `json:"text"`
}

type AdResponse struct {
	Ads []*Ad `json:"ads"`
}
