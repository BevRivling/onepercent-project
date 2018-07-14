import { combineReducers } from 'redux'
import { routerReducer } from 'react-router-redux'
import web3Reducer from './utils/web3Reducer'

const reducer = combineReducers({
  routing: routerReducer,
  web3: web3Reducer
})

export default reducer
