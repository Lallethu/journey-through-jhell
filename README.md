# Journey Trough Jhell

> By day, a candy village. By dusk, the world have to face Jhell.

A small day/night survival game made for LÖVE Jam 2026 [B-Side](https://itch.io/jam/lve-jam-2026-b-side).

Theme: **Jelly**.

## Play

- Make sure you have LÖVE installed: [LÖVE web site](https://love2d.org)
- Desktop: download `journey-trough-jhell.love` and run it with LÖVE 11.5 @ [Journey Trough Jhell](https://lallethu.itch.io/journey-trough-jhell)

## Controls

| Phase | Key | Action |
| --- | --- | --- |
| Day | Arrows / WASD | Move |
| Day | E | Interact |
| Day | Enter | Skip day time |
| Day | X | Close current task |
| Night | Space | Attack |
| Night | Q | Place wall |
| Night | F | Heal |
| Win/Lose | Enter | Restart a run |

## How to play

Spend the day gathering sugar and hardening the village. When dusk
falls, the jelly comes out. Survive the nights.

## Content notice

Cartoon creature violence only. No mature content.

## Development

- LÖVE 11.5, LuaJIT
- Run: `love .` (or `Ctrl+Shift+B` in VS Code)
- Build: see `.vscode/tasks.json`
- Structure: `src/core` (generic tools), `src/states` (phase FSM),
  `src/world` (entities), `src/systems` (event listeners), `src/data` (tuning)

## Credits

- Code, art, design: Lallethu (me, hehe)
- music: L. Alexandre (aka R C), for the title "Candy passion" OST for the game

see also [CREDITS](CREDITS.md)

## License

Code: MIT. Art and audio: CC BY-NC 4.0.
