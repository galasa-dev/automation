package types

type Commit struct {
	Commit CommitInt `json:"commit"`
}

type CommitInt struct {
	Author Author `json:"author"`
}

type Author struct {
	Date string `json:"date"`
}
