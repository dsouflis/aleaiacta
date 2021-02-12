import React, { useEffect } from 'react';

const Elm = window.Elm;

const stateKey = 'aleaiacta';

const getState = () => {
  const savedString = localStorage.getItem(stateKey) || "{}";
  const saved = JSON.parse(savedString);
  return saved;
};

export default ({
  sz = 4,
  seed = 0,
  goalScore = 100,
  goalChains = 10,
}) => {
  useEffect(() => {
    const flags = {
      sz,
      seed,
      goalScore,
      goalChains,
      now: Date.now(),
      names: Object.keys(getState())
    };

    const aleaiacta = Elm.Aleaiacta.init({
      node: document.getElementById("elm-area"),
      flags
    });
  }, []);

  return <div id="elm-area">Aleaiacta</div>;
}
