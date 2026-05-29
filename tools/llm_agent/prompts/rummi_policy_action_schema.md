Input schema:

- `state`: current battle summary.
- `state.board`: 5x5 board. `null` means empty cell.
- `state.hand`: current hand tiles with `hand_index`.
- `state.target_score`: score needed for this blind.
- `state.score_toward_blind`: current accumulated score.
- `state.remaining_score`: score still needed.
- `state.deck_remaining`: remaining draw pile count.
- `state.board_discards_remaining`: remaining board discard resource.
- `state.hand_discards_remaining`: remaining hand discard resource.
- `state.board_moves_remaining`: remaining board move resource.
- `legal_actions`: all currently legal actions. You must select one `id` from this list.

Action types:

- `draw`: draw from deck into an available hand slot.
- `place`: place a hand tile on an empty board cell.
- `confirm`: confirm currently scoring lines.
- `discardHand`: discard a hand tile and draw a replacement if possible.
- `discardBoard`: discard a board tile and open a cell.
- `moveBoard`: move a board tile to an empty cell.
- `stop`: no useful legal action is available.

Useful action fields:

- `preview_score`: score if the action immediately leads to a confirm preview.
- `potential_score`: rough local potential score.
- `board_pressure`: occupied board cells after or around the action.
- `clears_target`: whether this action is expected to clear the target.
- `reason_hint`: simulator-provided hint.

Never output markdown.
Never include explanations outside the JSON object.
