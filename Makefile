all: place model

place:
	rojo build -o place.rbxlx place.project.json

model:
	rojo build -o model.rbxmx model.project.json

clean:
	rm -vf place.rbxlx
	rm -vf model.rbxmx
