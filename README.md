# Grand Theft Snodland

A deliberately small-scope, top-down 3D open-world game set in a stylised but geographically recognisable Snodland, Kent. Inspired by the elevated, semi-angled presentation of GTA Bridgwater.

## Project direction

- Engine: Godot 4 / GDScript
- Camera: elevated, semi-angled top-down 3D
- Targets: PC and Android; browser export to be tested
- World: real Snodland geography using OpenStreetMap data with appropriate attribution
- Art: lightweight procedural placeholders first; Blender modelling deferred

## First playable milestone: A New Start

The current scene is a temporary blockout, not the real Snodland map yet.

1. Player arrives at a placeholder train station.
2. Phone message introduces the town and starter flat.
3. Player receives £500, reserved for the £450 flat rental.
4. Follow the objective towards the placeholder High Street.
5. Press E at the glowing rental marker to rent the flat.
6. Mission completes and the flat becomes the save point.
7. Return to the flat marker and press E to save.
8. On the next launch, the saved rented-flat state and player position are restored.

## Controls

- WASD / arrow keys: move
- E: interact, rent or save
- Mouse: press the opening dialogue button

## Run

Open the repository in Godot 4.3 or newer and run the project. The project uses the Compatibility renderer as a low-demand starting point.

## Current implementation

- Procedural 3D greybox environment
- Player controller and elevated follow camera
- Placeholder NPCs and parked cars
- Opening phone-message overlay
- Starter money and rent-only first purchase flow
- Rental marker and first mission completion
- Local save/load file at user://snodland_save.cfg

## Next steps

1. Test in Godot and fix editor/runtime issues.
2. Replace the temporary blockout with real Snodland map geometry.
3. Improve the station-to-High-Street route and the starter flat entrance.
4. Add mobile controls and proper NPC/vehicle behaviour.

## Map data and attribution

When OpenStreetMap data is added, include the required OpenStreetMap attribution and comply with the ODbL. Check the terms of any third-party map extracts before redistribution.

## Development rule

Keep the first build small. Prioritise the map, player, basic NPCs and cars, then make the opening mission work. Defer unrelated systems until this sequence works.
